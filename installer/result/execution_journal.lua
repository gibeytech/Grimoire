local ExecutionJournal = {}

local RUNNER_RESULT_KEYS = {
   command = "runner",
   file_operation = "operation",
   service_operation = "service",
   shell_operation = "shell",
   hypr_activation = "hypr_activation",
}

local function resolve_runner_result(action, result)
   local details = result and result.details or {}
   local action_type = action and action.type or nil
   local result_key = RUNNER_RESULT_KEYS[action_type]

   if result_key
      and type(details[result_key]) == "table"
   then
      return details[result_key]
   end

   return nil
end

local function resolve_system_result(runner_result)
   if type(runner_result) ~= "table" then
      return nil
   end

   if type(runner_result.system) == "table" then
      return runner_result.system
   end

   if type(runner_result.system_result)
      ~= "table"
   then
      return nil
   end

   local filesystem_result =
      runner_result.system_result

   if type(filesystem_result.system_result)
      == "table"
   then
      return filesystem_result.system_result
   end

   if filesystem_result.stdout ~= nil
      or filesystem_result.stderr ~= nil
      or filesystem_result.exit_code ~= nil
   then
      return filesystem_result
   end

   return nil
end

local function clone_table(value)
   if type(value) ~= "table" then
      return nil
   end

   local clone = {}

   for key, item in pairs(value) do
      clone[key] = item
   end

   return clone
end

local function clone_retry_metadata(runner_result)
   if type(runner_result) ~= "table"
      or type(runner_result.retry) ~= "table"
   then
      return nil
   end

   local retry = runner_result.retry
   local clone = clone_table(retry)

   clone.exit_codes = {}

   for _, exit_code in ipairs(
      retry.exit_codes or {}
   ) do
      table.insert(clone.exit_codes, exit_code)
   end

   clone.attempt_results = {}

   for _, attempt in ipairs(
      retry.attempt_results or {}
   ) do
      table.insert(
         clone.attempt_results,
         clone_table(attempt)
      )
   end

   return clone
end

local function resolve_compensation(runner_result)
   if type(runner_result) ~= "table" then
      return nil
   end

   if type(runner_result.compensation)
      == "table"
   then
      return clone_table(
         runner_result.compensation
      )
   end

   if type(runner_result.system_result)
      == "table"
      and type(
         runner_result.system_result.compensation
      ) == "table"
   then
      return clone_table(
         runner_result.system_result.compensation
      )
   end

   return nil
end

local function resolve_command(
   action,
   result,
   runner_result
)
   if runner_result
      and runner_result.command ~= nil
   then
      return runner_result.command
   end

   if result and result.command ~= nil then
      return result.command
   end

   if action then
      return action.command
   end

   return nil
end

local function resolve_exit_code(
   runner_result,
   system_result
)
   if runner_result
      and runner_result.exit_code ~= nil
   then
      return runner_result.exit_code
   end

   if system_result then
      return system_result.exit_code
   end

   return nil
end

local function resolve_reason(
   runner_result,
   system_result
)
   if runner_result
      and runner_result.reason ~= nil
   then
      return runner_result.reason
   end

   if system_result then
      return system_result.reason
   end

   return nil
end

local function resolve_control_boolean(
   runner_result,
   system_result,
   field
)
   if runner_result
      and runner_result[field] == true
   then
      return true
   end

   return system_result
      and system_result[field] == true
      or false
end

local function resolve_control_value(
   runner_result,
   system_result,
   field
)
   if runner_result
      and runner_result[field] ~= nil
   then
      return runner_result[field]
   end

   if system_result then
      return system_result[field]
   end

   return nil
end

local function resolve_stream(system_result, field)
   if type(system_result) ~= "table" then
      return ""
   end

   local value = system_result[field]

   if value == nil then
      return ""
   end

   return tostring(value)
end

local function resolve_error(result, runner_result)
   if result and result.error ~= nil then
      return result.error
   end

   if runner_result then
      return runner_result.error
   end

   return nil
end

function ExecutionJournal.create_entry(
   action,
   result,
   context
)
   action = action or {}
   result = result or {}
   context = context or {}

   local runner_result = resolve_runner_result(
      action,
      result
   )

   local system_result = resolve_system_result(
      runner_result
   )

   local retry = clone_retry_metadata(
      runner_result
   )

   return {
      sequence = context.sequence or 0,
      total = context.total or 0,
      type = action.type or "unknown",
      manager = action.manager
         or result.manager
         or "unknown",
      name = action.name or "unknown",
      mode = runner_result
         and runner_result.mode
         or context.mode
         or "unknown",
      ok = result.ok == true,
      prepared = runner_result
         and runner_result.prepared == true
         or false,
      simulated = runner_result
         and runner_result.simulated == true
         or false,
      executed = runner_result
         and runner_result.executed == true
         or false,
      command = resolve_command(
         action,
         result,
         runner_result
      ),
      exit_code = resolve_exit_code(
         runner_result,
         system_result
      ),
      reason = resolve_reason(
         runner_result,
         system_result
      ),
      timed_out = resolve_control_boolean(
         runner_result,
         system_result,
         "timed_out"
      ),
      interrupted = resolve_control_boolean(
         runner_result,
         system_result,
         "interrupted"
      ),
      timeout_seconds = resolve_control_value(
         runner_result,
         system_result,
         "timeout_seconds"
      ),
      kill_after_seconds = resolve_control_value(
         runner_result,
         system_result,
         "kill_after_seconds"
      ),
      retry = retry,
      retry_enabled = retry
         and retry.enabled == true
         or false,
      retry_attempts = retry
         and retry.attempts
         or 0,
      retry_max_attempts = retry
         and retry.max_attempts
         or 1,
      retried = retry
         and retry.retried == true
         or false,
      retry_exhausted = retry
         and retry.exhausted == true
         or false,
      retry_stopped_reason = retry
         and retry.stopped_reason
         or nil,
      stdout = resolve_stream(
         system_result,
         "stdout"
      ),
      stderr = resolve_stream(
         system_result,
         "stderr"
      ),
      compensation = resolve_compensation(
         runner_result
      ),
      error = resolve_error(
         result,
         runner_result
      ),
   }
end

return ExecutionJournal
