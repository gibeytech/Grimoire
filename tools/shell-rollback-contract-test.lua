package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local FileOperations = require(
   "installer.file_operations"
)

local ShellRollback = require(
   "installer.shell_rollback"
)

print(
   "== ShellRollback RC4-B3 Contract Test =="
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

local copy_result =
   FileOperations.run({
      type = "copy",
      source = source,
      destination = destination,
      overwrite = false,
   }, {
      dry_run = false,
      apply_real = true,
   })

assert(copy_result.ok == true)
assert(path_exists(destination))

local metadata = {
   kind = "shell",
   status = "ready",
   eligible = true,
   reversible = true,
   compensation_type =
      "remove-created-runtime",
   runtime = "grimoire-shell",
   strategy = "copy",
   source = source,
   destination = destination,
   entrypoint = "shell.qml",
   created_destination = true,
   destination_existed_before = false,
   filesystem = copy_result.compensation,
   reason = nil,
}

local rollback =
   ShellRollback.run(
      metadata,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(rollback.ok == true)
assert(rollback.status == "removed")
assert(rollback.executed == true)
assert(rollback.removed == true)
assert(path_exists(destination) == false)
assert(path_exists(source) == true)

local repeated =
   ShellRollback.run(
      metadata,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(repeated.ok == true)
assert(repeated.status == "already-absent")
assert(repeated.already_absent == true)

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
   "RC4-B3 OK : le rollback Shell supprime "
      .. "uniquement le runtime créé."
)
