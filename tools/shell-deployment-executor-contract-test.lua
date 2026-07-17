package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ShellDeploymentExecutor = require(
   "installer.shell_deployment_executor"
)

print(
   "== ShellDeploymentExecutor RC4-B2 Contract Test =="
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

local function path_exists(path)
   return command_succeeded(
      "test -e "
         .. shell_quote(path)
         .. " || test -L "
         .. shell_quote(path)
   )
end

local function is_symlink(path)
   return command_succeeded(
      "test -L "
         .. shell_quote(path)
   )
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

assert(
   command_succeeded(
      "mkdir -p -- "
         .. shell_quote(
            temporary_directory
               .. "/source/core"
         )
   )
)

local source =
   temporary_directory .. "/source"

local destination =
   temporary_directory .. "/deployed"

local symlink_destination =
   temporary_directory .. "/linked"

write_file(
   source .. "/shell.qml",
   "import QtQuick\n"
)

write_file(
   source .. "/core/runtime.qml",
   "QtObject {}\n"
)

local contract = {
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

local first =
   ShellDeploymentExecutor.run(
      contract,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(first.ok == true)
assert(first.status == "deployed")
assert(first.executed == true)
assert(first.changed == true)
assert(first.already_satisfied == false)
assert(first.reason == "deployed")
assert(path_exists(destination))
assert(path_exists(destination .. "/shell.qml"))
assert(first.compensation.status == "ready")
assert(first.compensation.reversible == true)

local second =
   ShellDeploymentExecutor.run(
      contract,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(second.ok == true)
assert(second.status == "already-satisfied")
assert(second.executed == false)
assert(second.changed == false)
assert(second.already_satisfied == true)
assert(second.reason == "already-satisfied")
assert(second.compensation.status == "not-executed")

write_file(
   destination .. "/core/runtime.qml",
   "contenu divergent\n"
)

local conflict =
   ShellDeploymentExecutor.run(
      contract,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(conflict.ok == false)
assert(conflict.status == "conflict")
assert(conflict.executed == false)
assert(conflict.reason == "destination-conflict")

local skip_contract = {}

for key, value in pairs(contract) do
   skip_contract[key] = value
end

skip_contract.overwrite = "skip"

local skipped =
   ShellDeploymentExecutor.run(
      skip_contract,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(skipped.ok == true)
assert(skipped.status == "skipped")
assert(skipped.executed == false)
assert(skipped.skipped == true)

local force_contract = {}

for key, value in pairs(contract) do
   force_contract[key] = value
end

force_contract.overwrite = "force"

local forced =
   ShellDeploymentExecutor.run(
      force_contract,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(forced.ok == false)
assert(forced.status == "unsupported")

local symlink_contract = {
   runtime = "grimoire-shell",
   modules = {
      "bar",
   },
   source = source,
   destination = symlink_destination,
   strategy = "symlink",
   overwrite = "error",
   entrypoint = "shell.qml",
}

local symlink_first =
   ShellDeploymentExecutor.run(
      symlink_contract,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(symlink_first.ok == true)
assert(symlink_first.executed == true)
assert(is_symlink(symlink_destination))
assert(symlink_first.compensation.status == "ready")

local symlink_second =
   ShellDeploymentExecutor.run(
      symlink_contract,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(symlink_second.ok == true)
assert(symlink_second.executed == false)
assert(symlink_second.already_satisfied == true)

local invalid_contract = {
   runtime = "grimoire-shell",
   modules = {
      "bar",
   },
   source = source,
   destination =
      temporary_directory .. "/invalid",
   strategy = "copy",
   overwrite = "error",
   entrypoint = "missing.qml",
}

local invalid =
   ShellDeploymentExecutor.run(
      invalid_contract,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(invalid.ok == false)
assert(invalid.status == "invalid")
assert(invalid.executed == false)
assert(not path_exists(invalid_contract.destination))

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
   "RC4-B2 OK : le runtime Shell est déployé, "
      .. "vérifié et reconnu comme déjà conforme."
)
