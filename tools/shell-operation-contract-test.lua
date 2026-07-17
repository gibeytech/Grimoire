package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ShellOperation = require(
   "installer.shell_operation"
)

print(
   "== ShellOperation RC4-B2 Contract Test =="
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

local dry_run =
   ShellOperation.run(
      action,
      {
         dry_run = true,
      }
   )

assert(dry_run.ok == true)
assert(dry_run.mode == "dry-run")
assert(dry_run.simulated == true)
assert(dry_run.executed == false)
assert(dry_run.reason == "dry-run")

local apply_safe =
   ShellOperation.run(
      action,
      {
         dry_run = false,
      }
   )

assert(apply_safe.ok == true)
assert(apply_safe.mode == "apply-safe")
assert(apply_safe.simulated == true)
assert(apply_safe.executed == false)

local apply_real =
   ShellOperation.run(
      action,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(apply_real.ok == true)
assert(apply_real.mode == "apply-real")
assert(apply_real.status == "deployed")
assert(apply_real.executed == true)
assert(apply_real.changed == true)
assert(apply_real.compensation.status == "ready")

local idempotent =
   ShellOperation.run(
      action,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(idempotent.ok == true)
assert(idempotent.executed == false)
assert(idempotent.changed == false)
assert(idempotent.already_satisfied == true)
assert(idempotent.reason == "already-satisfied")

local legacy =
   ShellOperation.run(
      {
         module = "hub",
         runtime = "grimoire-shell",
      },
      {
         dry_run = true,
      }
   )

assert(legacy.ok == true)
assert(legacy.explicit == false)
assert(legacy.module == "hub")

local legacy_real =
   ShellOperation.run(
      {
         module = "hub",
         runtime = "grimoire-shell",
      },
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(legacy_real.ok == false)
assert(
   legacy_real.reason
      == "legacy-apply-real-unsupported"
)

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
   "RC4-B2 OK : ShellOperation active "
      .. "l’apply-real idempotent."
)
