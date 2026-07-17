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
   "== Shell RC4-B2 Apply-Real Integration Test =="
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
   local ok, _, code =
      os.execute(command)

   return ok == true
      or ok == 0
      or code == 0
end

local function write_file(path, content)
   local file, open_error =
      io.open(path, "wb")

   assert(file, open_error)
   assert(file:write(content))
   file:close()
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
   temporary_directory .. "/destination"

assert(
   command_succeeded(
      "mkdir -p -- "
         .. shell_quote(source)
   )
)

write_file(
   source .. "/shell.qml",
   "import QtQuick\n"
)

local action = {
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
}

local plan =
   ExecutionPlan:new({
      profile = {
         id = "shell-apply-real",
         name = "Shell Apply Real",
      },
      mode = "apply-real",
      actions = {
         action,
      },
   })

local first =
   Executor.execute(
      plan,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(first.ok == true)
assert(first.executed_actions == 1)
assert(first.transaction_status == "committed")
assert(#first.results == 1)
assert(#first.journal == 1)

local first_shell =
   first.results[1].details.shell

assert(first_shell.ok == true)
assert(first_shell.executed == true)
assert(first_shell.changed == true)
assert(first_shell.compensation.status == "ready")
assert(first.journal[1].compensation.status == "ready")
assert(first.journal[1].compensation.reversible == true)

local second =
   Executor.execute(
      plan,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(second.ok == true)
assert(second.executed_actions == 0)
assert(second.transaction_status == "committed")

local second_shell =
   second.results[1].details.shell

assert(second_shell.ok == true)
assert(second_shell.executed == false)
assert(second_shell.changed == false)
assert(second_shell.already_satisfied == true)
assert(second_shell.reason == "already-satisfied")
assert(second.journal[1].reason == "already-satisfied")

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
   "RC4-B2 OK : Executor déploie et journalise "
      .. "le runtime Shell de manière idempotente."
)
