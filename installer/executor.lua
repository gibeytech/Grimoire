local ActionDispatcher = require(
   "installer.action_dispatcher"
)

local ExecutionJournal = require(
   "installer.result.execution_journal"
)

local ExecutionTransaction = require(
   "installer.execution_transaction"
)

local Executor = {}

local function resolve_mode(options)
   options = options or {}

   if options.dry_run ~= false then
      return "dry-run"
   end

   if options.apply_real == true then
      return "apply-real"
   end

   return "apply-safe"
end

local function resolve_runner_result(details)
   details = details or {}

   if type(details.runner) == "table" then
      return details.runner
   end

   if type(details.service) == "table" then
      return details.service
   end

   if type(details.shell) == "table" then
      return details.shell
   end

   if type(details.operation) == "table" then
      return details.operation
   end

   return nil
end

local function count_executed_actions(results)
   local total = 0

   for _, result in ipairs(results or {}) do
      local runner_result =
         resolve_runner_result(
            result.details
         )

      if runner_result
         and runner_result.executed == true
      then
         total = total + 1
      end
   end

   return total
end

local function count_total_attempts(journal)
   local total = 0

   for _, entry in ipairs(journal or {}) do
      total = total + (entry.retry_attempts or 0)
   end

   return total
end

local function count_retried_actions(journal)
   local total = 0

   for _, entry in ipairs(journal or {}) do
      if entry.retried == true then
         total = total + 1
      end
   end

   return total
end

local function resolve_failure_status(rollback)
   if rollback
      and rollback.attempted == true
   then
      if rollback.ok == true then
         return "rolled-back"
      end

      return "rollback-failed"
   end

   return "failed"
end

local function resolve_failure_kind(journal)
   local entry = journal and journal[#journal]

   if entry and entry.timed_out == true then
      return "timeout"
   end

   if entry and entry.interrupted == true then
      return "interrupted"
   end

   return "error"
end

local function resolve_control_metadata(journal)
   local entry = journal and journal[#journal] or {}

   return {
      timed_out = entry.timed_out == true,
      interrupted = entry.interrupted == true,
      timeout_seconds = entry.timeout_seconds,
      kill_after_seconds =
         entry.kill_after_seconds,
      retry_attempts = entry.retry_attempts or 0,
      retry_exhausted =
         entry.retry_exhausted == true,
      retry_stopped_reason =
         entry.retry_stopped_reason,
   }
end

local function failure_result(
   mode,
   failed_result,
   results,
   journal,
   transaction
)
   local rollback = transaction:rollback()
   local control = resolve_control_metadata(journal)

   return {
      ok = false,
      dry_run = mode == "dry-run",
      mode = mode,
      transaction_status =
         resolve_failure_status(rollback),
      failure_kind = resolve_failure_kind(journal),
      timed_out = control.timed_out,
      interrupted = control.interrupted,
      timeout_seconds = control.timeout_seconds,
      kill_after_seconds =
         control.kill_after_seconds,
      retry_attempts = control.retry_attempts,
      retry_exhausted = control.retry_exhausted,
      retry_stopped_reason =
         control.retry_stopped_reason,
      total_attempts = count_total_attempts(journal),
      retried_actions =
         count_retried_actions(journal),
      failed_at = failed_result.manager,
      results = results,
      journal = journal,
      rollback = rollback,
      error = failed_result.error,
      executed_actions =
         count_executed_actions(results),
   }
end

local function print_mode(mode)
   if mode == "dry-run" then
      print("[Executor] Mode dry-run actif")
      return
   end

   if mode == "apply-safe" then
      print("[Executor] Mode apply sécurisé actif")
      print(
         "[Executor] Aucune action système réelle "
            .. "ne sera exécutée"
      )
      return
   end

   if mode == "apply-real" then
      print("[Executor] Mode apply réel actif")
      print(
         "[Executor] Les actions compatibles pourront "
            .. "modifier le système"
      )
      return
   end

   print(
      "[Executor] Mode inconnu : "
         .. tostring(mode)
   )
end

function Executor.run(execution_plan, options)
   options = options or {}

   local mode = resolve_mode(options)
   local dry_run = mode == "dry-run"
   local results = {}
   local journal = {}

   local transaction =
      ExecutionTransaction.new({
         mode = mode,
      })

   print("== Grimoire V3 Executor ==")
   print_mode(mode)

   if not execution_plan
      or type(execution_plan.getActions)
         ~= "function"
   then
      return {
         ok = false,
         dry_run = dry_run,
         mode = mode,
         transaction_status = "invalid",
         failure_kind = "invalid",
         timed_out = false,
         interrupted = false,
         timeout_seconds = nil,
         kill_after_seconds = nil,
         retry_attempts = 0,
         retry_exhausted = false,
         retry_stopped_reason = nil,
         total_attempts = 0,
         retried_actions = 0,
         failed_at = "executor",
         results = results,
         journal = journal,
         rollback =
            ExecutionTransaction.not_required(
               mode,
               "not-required"
            ),
         error = "Executor attend un ExecutionPlan",
         executed_actions = 0,
      }
   end

   local actions =
      execution_plan:getActions() or {}

   local total_actions =
      execution_plan:countActions()

   for index, action in ipairs(actions) do
      print("")
      print(
         "[Executor] Action "
            .. tostring(index)
            .. "/"
            .. tostring(total_actions)
      )

      local result = ActionDispatcher.dispatch(
         action,
         options
      )

      table.insert(results, result)

      local journal_entry =
         ExecutionJournal.create_entry(
            action,
            result,
            {
               sequence = index,
               total = total_actions,
               mode = mode,
            }
         )

      table.insert(
         journal,
         journal_entry
      )

      transaction:register(
         journal_entry
      )

      if not result.ok then
         return failure_result(
            mode,
            result,
            results,
            journal,
            transaction
         )
      end
   end

   return {
      ok = true,
      dry_run = dry_run,
      mode = mode,
      transaction_status = "committed",
      failure_kind = nil,
      timed_out = false,
      interrupted = false,
      timeout_seconds = nil,
      kill_after_seconds = nil,
      retry_attempts = 0,
      retry_exhausted = false,
      retry_stopped_reason = nil,
      total_attempts = count_total_attempts(journal),
      retried_actions =
         count_retried_actions(journal),
      results = results,
      journal = journal,
      rollback =
         ExecutionTransaction.not_required(
            mode,
            "not-required"
         ),
      error = nil,
      executed_actions =
         count_executed_actions(results),
   }
end

function Executor.execute(
   execution_plan,
   options
)
   return Executor.run(
      execution_plan,
      options
   )
end

return Executor
