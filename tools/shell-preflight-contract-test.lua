package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ShellPreflight = require(
   "installer.shell_preflight"
)

print(
   "== ShellPreflight RC4-B4 Contract Test =="
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

local temporary_directory = os.tmpname()

os.remove(temporary_directory)

assert(
   temporary_directory:match("^/tmp/")
)

local source =
   temporary_directory .. "/source"

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

local action = {
   runtime = "grimoire-shell",
   modules = {
      "bar",
      "hub",
   },
   source = source,
   destination =
      temporary_directory .. "/destination",
   strategy = "copy",
   overwrite = "error",
   entrypoint = "shell.qml",
   timeout_seconds = 12,
   kill_after_seconds = 3,
}

local ready =
   ShellPreflight.run(
      action,
      {
         runtime_command = "sh",
      }
   )

assert(ready.ok == true)
assert(ready.deployment_ready == true)
assert(ready.runtime_available == true)
assert(ready.timeout_seconds == 12)
assert(ready.kill_after_seconds == 3)
assert(#ready.missing_tools == 0)
assert(#ready.warnings == 0)

local runtime_missing =
   ShellPreflight.run(
      action,
      {
         runtime_command =
            "grimoire-command-absente",
      }
   )

assert(runtime_missing.ok == true)
assert(runtime_missing.deployment_ready == true)
assert(runtime_missing.runtime_available == false)
assert(#runtime_missing.warnings == 1)

local missing_entrypoint = {}

for key, value in pairs(action) do
   missing_entrypoint[key] = value
end

missing_entrypoint.entrypoint = "missing.qml"

local invalid =
   ShellPreflight.run(
      missing_entrypoint,
      {
         runtime_command = "sh",
      }
   )

assert(invalid.ok == false)
assert(invalid.deployment_ready == false)

local unsafe = {}

for key, value in pairs(action) do
   unsafe[key] = value
end

unsafe.destination = "/"

local unsafe_result =
   ShellPreflight.run(
      unsafe,
      {
         runtime_command = "sh",
      }
   )

assert(unsafe_result.ok == false)
assert(unsafe_result.deployment_ready == false)

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
   "RC4-B4 OK : le préflight distingue "
      .. "les prérequis de déploiement du runtime disponible."
)
