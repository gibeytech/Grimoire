local RetryPolicy = require(
   "installer.retry_policy"
)
local ActionDispatcher = require(
   "installer.action_dispatcher"
)
local ExecutionPlan = require(
   "installer.model.execution_plan"
)
local Executor = require("installer.executor")

print("== RC3-C2 Execution Retry Contract Test ==")

local function shell_quote(value)
   local string_value = tostring(value)

   return "'" .. string_value:gsub("'", "'\\''") .. "'"
end

local function execute_ok(command)
   local ok, _, code = os.execute(command)

   if ok == true then
      return true
   end

   return type(ok) == "number" and ok == 0
      or code == 0
end

local function path_exists(path)
   return execute_ok(
      "test -e " .. shell_quote(path)
         .. " || test -L " .. shell_quote(path)
   )
end

local function make_temp_directory()
   local path = os.tmpname()

   os.remove(path)

   assert(execute_ok(
      "mkdir -p -- " .. shell_quote(path)
   ))

   return path
end

local function write_file(path, content)
   local file = assert(io.open(path, "wb"))

   assert(file:write(content))
   assert(file:close())
end

local function write_executable(path, content)
   write_file(path, content)

   assert(execute_ok(
      "chmod 700 -- " .. shell_quote(path)
   ))
end

local function read_number(path)
   local file = assert(io.open(path, "rb"))
   local content = assert(file:read("*a"))

   assert(file:close())

   return assert(tonumber(content))
end

local function remove_tree(path)
   execute_ok("rm -rf -- " .. shell_quote(path))
end

local function command_action(name, command, retry)
   return {
      type = "command",
      manager = "packages",
      name = name,
      command = command,
      retry = retry,
   }
end

local function apply_real_options(extra)
   local options = {
      dry_run = false,
      apply_real = true,
   }

   for key, value in pairs(extra or {}) do
      options[key] = value
   end

   return options
end

local temp_root = make_temp_directory()

local retry_counter = temp_root .. "/retry-counter"
local retry_script = temp_root .. "/retry-success.sh"

write_executable(
   retry_script,
   table.concat({
      "#!/bin/sh",
      "counter=" .. shell_quote(retry_counter),
      "value=0",
      "if [ -f \"$counter\" ]; then value=$(cat \"$counter\"); fi",
      "value=$((value + 1))",
      "printf '%s' \"$value\" > \"$counter\"",
      "if [ \"$value\" -lt 2 ]; then exit 75; fi",
      "printf '%s\\n' 'retry-success'",
      "exit 0",
      "",
   }, "\n")
)

-- Le retry est absent par défaut.
local default_failure = ActionDispatcher.dispatch(
   command_action(
      "default-no-retry",
      "exit 75",
      nil
   ),
   apply_real_options()
)

assert(default_failure.ok == false)
assert(default_failure.details.runner.retry.enabled == false)
assert(default_failure.details.runner.retry.attempts == 1)
assert(default_failure.details.runner.retry.retried == false)
assert(
   default_failure.details.runner.retry.stopped_reason
      == "disabled"
)

-- Une commande explicitement rejouable réussit au second essai.
local retry_success = ActionDispatcher.dispatch(
   command_action(
      "retry-success",
      shell_quote(retry_script),
      {
         replay_safe = true,
         max_attempts = 3,
         exit_codes = { 75 },
      }
   ),
   apply_real_options()
)

assert(retry_success.ok == true)
assert(read_number(retry_counter) == 2)

local retry_success_metadata =
   retry_success.details.runner.retry

assert(retry_success_metadata.enabled == true)
assert(retry_success_metadata.max_attempts == 3)
assert(retry_success_metadata.attempts == 2)
assert(retry_success_metadata.retried == true)
assert(retry_success_metadata.exhausted == false)
assert(retry_success_metadata.stopped_reason == "success")
assert(#retry_success_metadata.attempt_results == 2)
assert(retry_success_metadata.attempt_results[1].exit_code == 75)
assert(retry_success_metadata.attempt_results[2].ok == true)

-- Un code non autorisé n'est jamais rejoué.
local non_matching_counter = temp_root .. "/non-matching-counter"
local non_matching_script = temp_root .. "/non-matching.sh"

write_executable(
   non_matching_script,
   table.concat({
      "#!/bin/sh",
      "counter=" .. shell_quote(non_matching_counter),
      "value=0",
      "if [ -f \"$counter\" ]; then value=$(cat \"$counter\"); fi",
      "value=$((value + 1))",
      "printf '%s' \"$value\" > \"$counter\"",
      "exit 2",
      "",
   }, "\n")
)

local non_matching = ActionDispatcher.dispatch(
   command_action(
      "non-matching-exit-code",
      shell_quote(non_matching_script),
      {
         replay_safe = true,
         max_attempts = 3,
         exit_codes = { 75 },
      }
   ),
   apply_real_options()
)

assert(non_matching.ok == false)
assert(read_number(non_matching_counter) == 1)
assert(non_matching.details.runner.retry.attempts == 1)
assert(
   non_matching.details.runner.retry.stopped_reason
      == "not-eligible"
)

-- Une politique épuisée s'arrête exactement à sa borne.
local exhausted_counter = temp_root .. "/exhausted-counter"
local exhausted_script = temp_root .. "/exhausted.sh"

write_executable(
   exhausted_script,
   table.concat({
      "#!/bin/sh",
      "counter=" .. shell_quote(exhausted_counter),
      "value=0",
      "if [ -f \"$counter\" ]; then value=$(cat \"$counter\"); fi",
      "value=$((value + 1))",
      "printf '%s' \"$value\" > \"$counter\"",
      "exit 75",
      "",
   }, "\n")
)

local exhausted = ActionDispatcher.dispatch(
   command_action(
      "retry-exhausted",
      shell_quote(exhausted_script),
      {
         replay_safe = true,
         max_attempts = 3,
         exit_codes = { 75 },
      }
   ),
   apply_real_options()
)

assert(exhausted.ok == false)
assert(read_number(exhausted_counter) == 3)
assert(exhausted.details.runner.retry.attempts == 3)
assert(exhausted.details.runner.retry.retried == true)
assert(exhausted.details.runner.retry.exhausted == true)
assert(
   exhausted.details.runner.retry.stopped_reason
      == "exhausted"
)

-- Un timeout n'est rejoué que sur autorisation dédiée.
local timeout_without_retry = ActionDispatcher.dispatch(
   command_action(
      "timeout-without-retry",
      "sleep 1",
      {
         replay_safe = true,
         max_attempts = 2,
         exit_codes = { 124 },
      }
   ),
   apply_real_options({
      timeout_seconds = 0.05,
      kill_after_seconds = 0.05,
   })
)

assert(timeout_without_retry.ok == false)
assert(timeout_without_retry.details.runner.timed_out == true)
assert(timeout_without_retry.details.runner.retry.attempts == 1)
assert(
   timeout_without_retry.details.runner.retry.stopped_reason
      == "timeout-not-enabled"
)

local timeout_with_retry = ActionDispatcher.dispatch(
   command_action(
      "timeout-with-retry",
      "sleep 1",
      {
         replay_safe = true,
         max_attempts = 2,
         retry_on_timeout = true,
      }
   ),
   apply_real_options({
      timeout_seconds = 0.05,
      kill_after_seconds = 0.05,
   })
)

assert(timeout_with_retry.ok == false)
assert(timeout_with_retry.details.runner.timed_out == true)
assert(timeout_with_retry.details.runner.retry.attempts == 2)
assert(timeout_with_retry.details.runner.retry.exhausted == true)

-- Une interruption n'est jamais rejouée.
local interrupted = ActionDispatcher.dispatch(
   command_action(
      "interrupted-command",
      "sh -c 'kill -INT $$'",
      {
         replay_safe = true,
         max_attempts = 3,
         exit_codes = { 130 },
         retry_on_timeout = true,
      }
   ),
   apply_real_options()
)

assert(interrupted.ok == false)
assert(interrupted.details.runner.interrupted == true)
assert(interrupted.details.runner.retry.attempts == 1)
assert(
   interrupted.details.runner.retry.stopped_reason
      == "interrupted"
)

-- Les politiques non bornées ou appliquées au filesystem sont rejetées.
local invalid_policy, invalid_policy_error =
   RetryPolicy.resolve(command_action(
      "invalid-policy",
      "true",
      {
         replay_safe = true,
         max_attempts = 6,
         exit_codes = { 75 },
      }
   ))

assert(invalid_policy == nil)
assert(
   invalid_policy_error:find("compris entre 2 et 5", 1, true)
      ~= nil
)

local forbidden_destination =
   temp_root .. "/forbidden-retry-copy.txt"

local forbidden_filesystem_retry =
   ActionDispatcher.dispatch(
      {
         type = "file_operation",
         manager = "assets",
         name = "forbidden-filesystem-retry",
         operation = {
            type = "copy",
            source = retry_script,
            destination = forbidden_destination,
            overwrite = false,
         },
         retry = {
            replay_safe = true,
            max_attempts = 2,
            exit_codes = { 75 },
         },
      },
      apply_real_options()
   )

assert(forbidden_filesystem_retry.ok == false)
assert(forbidden_filesystem_retry.actions == 0)
assert(path_exists(forbidden_destination) == false)
assert(
   forbidden_filesystem_retry.error:find(
      "réservé aux actions command",
      1,
      true
   ) ~= nil
)

-- Executor journalise l'épuisement puis déclenche le rollback.
local rollback_source = temp_root .. "/rollback-source.txt"
local rollback_destination =
   temp_root .. "/rollback-destination.txt"
local transaction_counter =
   temp_root .. "/transaction-counter"
local transaction_script =
   temp_root .. "/transaction-failure.sh"

write_file(rollback_source, "rollback retry\n")

write_executable(
   transaction_script,
   table.concat({
      "#!/bin/sh",
      "counter=" .. shell_quote(transaction_counter),
      "value=0",
      "if [ -f \"$counter\" ]; then value=$(cat \"$counter\"); fi",
      "value=$((value + 1))",
      "printf '%s' \"$value\" > \"$counter\"",
      "exit 75",
      "",
   }, "\n")
)

local plan = ExecutionPlan:new({
   profile = {
      id = "rc3-c2-retry",
   },
   mode = "apply-real",
   actions = {
      {
         type = "file_operation",
         manager = "assets",
         name = "copy-before-retry-failure",
         operation = {
            type = "copy",
            source = rollback_source,
            destination = rollback_destination,
            overwrite = false,
         },
      },
      command_action(
         "transaction-retry-failure",
         shell_quote(transaction_script),
         {
            replay_safe = true,
            max_attempts = 2,
            exit_codes = { 75 },
         }
      ),
   },
})

local execution = Executor.execute(
   plan,
   apply_real_options()
)

assert(execution.ok == false)
assert(execution.transaction_status == "rolled-back")
assert(execution.failure_kind == "error")
assert(execution.retry_attempts == 2)
assert(execution.retry_exhausted == true)
assert(execution.retry_stopped_reason == "exhausted")
assert(execution.total_attempts == 3)
assert(execution.retried_actions == 1)
assert(#execution.journal == 2)
assert(execution.journal[1].retry_enabled == false)
assert(execution.journal[1].retry_attempts == 1)
assert(execution.journal[2].retry_enabled == true)
assert(execution.journal[2].retry_attempts == 2)
assert(execution.journal[2].retried == true)
assert(execution.journal[2].retry_exhausted == true)
assert(
   execution.journal[2].retry_stopped_reason
      == "exhausted"
)
assert(type(execution.journal[2].retry) == "table")
assert(#execution.journal[2].retry.attempt_results == 2)
assert(execution.rollback.attempted == true)
assert(execution.rollback.ok == true)
assert(path_exists(rollback_destination) == false)
assert(read_number(transaction_counter) == 2)

remove_tree(temp_root)

print(
   "RC3-C2 OK : le retry est explicite, borné, filtré, "
      .. "journalisé et compatible avec le rollback transactionnel."
)
