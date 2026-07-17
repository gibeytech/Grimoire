package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ExecutionPlan = require(
   "installer.model.execution_plan"
)

local Executor = require(
   "installer.executor"
)

print(
   "== Shell RC4-B3 Transaction Integration Test =="
)

local function shell_quote(value)
   return "'"
      .. tostring(value):gsub(
         "'",
         "'\\''"
      )
      .. "'"
end

local function command_succeeded(command)
   local ok, _, code = os.execute(command)

   return ok == true
      or ok == 0
      or code == 0
end

local function path_exists(path)
   return command_succeeded(
      "test -e "
         .. shell_quote(path)
         .. " || test -L "
         .. shell_quote(path)
   )
end

local temporary_directory =
   os.tmpname()

os.remove(temporary_directory)

assert(
   temporary_directory:match("^/tmp/")
)

local source =
   temporary_directory .. "/source"

local destination =
   temporary_directory .. "/runtime"

assert(
   command_succeeded(
      "mkdir -p -- "
         .. shell_quote(source)
   )
)

local file = assert(
   io.open(source .. "/shell.qml", "wb")
)

assert(file:write("import QtQuick\n"))
file:close()

local plan =
   ExecutionPlan:new({
      profile = {
         id = "shell-transaction",
         name = "Shell Transaction",
      },
      mode = "apply-real",

      actions = {
         {
            type = "shell_operation",
            manager = "shell",
            name = "deploy-runtime",
            runtime = "grimoire-shell",

            modules = {
               "bar",
               "hub",
            },

            source = source,
            destination = destination,
            strategy = "copy",
            overwrite = "error",
            entrypoint = "shell.qml",
         },

         {
            type = "command",
            manager = "packages",
            name = "force-rollback",
            command = "false",
         },
      },
   })

local result =
   Executor.execute(
      plan,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(result.ok == false)

assert(
   result.transaction_status
      == "rolled-back"
)

assert(result.failed_at == "packages")
assert(result.executed_actions == 2)
assert(#result.journal == 2)

local shell_entry = result.journal[1]

assert(shell_entry.compensation.kind == "shell")
assert(shell_entry.compensation.status == "ready")
assert(shell_entry.compensation.reversible == true)

assert(result.rollback.attempted == true)
assert(result.rollback.ok == true)
assert(result.rollback.total_actions == 1)
assert(result.rollback.successful_actions == 1)

local rollback =
   result.rollback.results[1]

assert(rollback.manager == "shell")
assert(rollback.name == "deploy-runtime")
assert(rollback.status == "removed")
assert(rollback.result.runtime == "grimoire-shell")

assert(path_exists(destination) == false)
assert(path_exists(source) == true)

assert(
   command_succeeded(
      "rm -rf -- "
         .. shell_quote(
            temporary_directory
         )
   )
)

print("")
print(
   "RC4-B3 OK : un échec ultérieur restaure "
      .. "la transaction en supprimant le runtime Shell créé."
)
