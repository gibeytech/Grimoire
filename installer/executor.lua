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

local function count_executed_actions(results)
   local total = 0

   for _, result in ipairs(results or {}) do
      local details = result.details or {}

      local runner_result =
         details.runner
         or details.operation
         or details.service
         or details.shell

      if runner_result
         and runner_result.executed == true
      then
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

local function failure_result(
   mode,
   failed_result,
   results,
   journal,
   transaction
)
   local rollback = transaction:rollback()

   return {
      ok = false,
      dry_run = mode == "dry-run",
      mode = mode,
      transaction_status =
         resolve_failure_status(rollback),
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
