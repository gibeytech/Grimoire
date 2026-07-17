package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ShellOperation = require(
   "installer.shell_operation"
)

print(
   "== ShellOperation RC4-B1 Contract Test =="
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
   source =
      "../grimoire-shell/quickshell",
   destination =
      "/tmp/grimoire-shell",
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
assert(dry_run.prepared == true)
assert(dry_run.simulated == true)
assert(dry_run.executed == false)
assert(dry_run.explicit == true)
assert(#dry_run.modules == 2)
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

assert(
   apply_safe.reason
      == "apply-safe-blocked"
)

local apply_real =
   ShellOperation.run(
      action,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(apply_real.ok == false)
assert(apply_real.mode == "apply-real")
assert(apply_real.prepared == true)
assert(apply_real.executed == false)

assert(
   apply_real.reason
      == "apply-real-blocked"
)

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
assert(#legacy.modules == 1)

local invalid =
   ShellOperation.run(
      {
         runtime = "grimoire-shell",
         modules = {
            "bar",
         },
         source = "source",
      },
      {
         dry_run = true,
      }
   )

assert(invalid.ok == false)
assert(invalid.prepared == false)

print("")
print(
   "RC4-B1 OK : ShellOperation valide le contrat "
      .. "explicite tout en conservant le format hérité."
)
