local SystemExecutor = require(
   "installer.system_executor"
)
local CommandRunner = require(
   "installer.command_runner"
)
local ExecutionPlan = require(
   "installer.model.execution_plan"
)
local Executor = require("installer.executor")

print("== RC3-C1 Execution Resilience Contract Test ==")

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

local function remove_tree(path)
   execute_ok("rm -rf -- " .. shell_quote(path))
end

-- Exécution normale avec une limite explicite.
local success = SystemExecutor.execute(
   "printf '%s\\n' 'résilience-ok'",
   {
      timeout_seconds = 2,
      kill_after_seconds = 1,
   }
)

assert(success.ok == true)
assert(success.executed == true)
assert(success.exit_code == 0)
assert(success.timed_out == false)
assert(success.interrupted == false)
assert(success.timeout_seconds == 2)
assert(success.kill_after_seconds == 1)
assert(success.stdout == "résilience-ok\n")
assert(success.error == nil)

-- Timeout réel : le flux produit avant l'arrêt reste capturé.
local timed_out = SystemExecutor.execute(
   "printf '%s\\n' 'avant-timeout'; sleep 1; "
      .. "printf '%s\\n' 'apres-timeout'",
   {
      timeout_seconds = 0.1,
      kill_after_seconds = 0.1,
   }
)

assert(timed_out.ok == false)
assert(timed_out.executed == true)
assert(timed_out.exit_code == 124 or timed_out.exit_code == 137)
assert(timed_out.timed_out == true)
assert(timed_out.interrupted == false)
assert(timed_out.timeout_seconds == 0.1)
assert(timed_out.stdout:find("avant%-timeout") ~= nil)
assert(timed_out.stdout:find("apres%-timeout") == nil)
assert(
   timed_out.error
      == "Commande système interrompue par timeout"
)

-- Interruption explicite du processus enfant.
local interrupted = SystemExecutor.execute(
   "sh -c 'kill -INT $$'"
)

assert(interrupted.ok == false)
assert(interrupted.executed == true)
assert(interrupted.timed_out == false)
assert(interrupted.interrupted == true)
assert(
   interrupted.error
      == "Commande système interrompue"
)

-- Une configuration de timeout invalide ne lance rien.
local invalid_timeout = SystemExecutor.execute(
   "true",
   {
      timeout_seconds = 0,
   }
)

assert(invalid_timeout.ok == false)
assert(invalid_timeout.executed == false)
assert(invalid_timeout.timed_out == false)
assert(invalid_timeout.interrupted == false)
assert(invalid_timeout.error == "Timeout système invalide")

-- CommandRunner propage le contrat normalisé.
local runner_timeout = CommandRunner.run(
   "sleep 1",
   {
      dry_run = false,
      apply_real = true,
      timeout_seconds = 0.1,
      kill_after_seconds = 0.1,
   }
)

assert(runner_timeout.ok == false)
assert(runner_timeout.executed == true)
assert(runner_timeout.timed_out == true)
assert(runner_timeout.interrupted == false)
assert(runner_timeout.timeout_seconds == 0.1)
assert(type(runner_timeout.system) == "table")

-- Executor transforme le timeout en échec transactionnel
-- puis annule l'action filesystem déjà validée.
local temp_root = make_temp_directory()
local source_path = temp_root .. "/source.txt"
local destination_path = temp_root .. "/destination.txt"

write_file(source_path, "contenu résilience\n")

local plan = ExecutionPlan:new({
   profile = {
      id = "rc3-c1-resilience",
   },
   mode = "apply-real",
   actions = {
      {
         type = "file_operation",
         manager = "assets",
         name = "copy-before-timeout",
         operation = {
            type = "copy",
            source = source_path,
            destination = destination_path,
            overwrite = false,
         },
      },
      {
         type = "command",
         manager = "packages",
         name = "timeout-command",
         command = "sleep 1",
      },
   },
})

local execution = Executor.execute(
   plan,
   {
      dry_run = false,
      apply_real = true,
      timeout_seconds = 0.1,
      kill_after_seconds = 0.1,
   }
)

assert(execution.ok == false)
assert(execution.mode == "apply-real")
assert(execution.transaction_status == "rolled-back")
assert(execution.failure_kind == "timeout")
assert(execution.timed_out == true)
assert(execution.interrupted == false)
assert(execution.timeout_seconds == 0.1)
assert(execution.failed_at == "packages")
assert(#execution.results == 2)
assert(#execution.journal == 2)
assert(execution.journal[1].ok == true)
assert(execution.journal[1].timed_out == false)
assert(execution.journal[2].ok == false)
assert(execution.journal[2].timed_out == true)
assert(execution.journal[2].interrupted == false)
assert(execution.rollback.attempted == true)
assert(execution.rollback.ok == true)
assert(execution.rollback.status == "completed")
assert(path_exists(destination_path) == false)

remove_tree(temp_root)

print(
   "RC3-C1 OK : timeout et interruption sont normalisés, "
      .. "journalisés et déclenchent le rollback transactionnel."
)
