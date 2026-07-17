package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ShellCompensationMetadata = require(
   "installer.result.shell_compensation_metadata"
)

print(
   "== ShellCompensationMetadata RC4-B3 Contract Test =="
)

local ready =
   ShellCompensationMetadata.complete({
      runtime = "grimoire-shell",
      strategy = "copy",
      source_resolved = "/tmp/source",
      destination = "/tmp/destination",
      entrypoint = "shell.qml",
      executed = true,
      changed = true,

      compensation = {
         kind = "filesystem",
         status = "ready",
         eligible = true,
         reversible = true,
         compensation_type =
            "remove-created-path",
         operation_type = "copy",
         source = "/tmp/source",
         destination = "/tmp/destination",
         overwrite = false,
         created_destination = true,
         destination_existed_before = false,
         previous_destination = nil,
         reason = nil,
      },
   })

assert(ready.kind == "shell")
assert(ready.status == "ready")
assert(ready.eligible == true)
assert(ready.reversible == true)

assert(
   ready.compensation_type
      == "remove-created-runtime"
)

assert(ready.runtime == "grimoire-shell")
assert(ready.destination == "/tmp/destination")
assert(type(ready.filesystem) == "table")
assert(ready.filesystem.kind == "filesystem")

local unchanged =
   ShellCompensationMetadata.complete({
      runtime = "grimoire-shell",
      destination = "/tmp/existing",
      executed = false,
      changed = false,
      already_satisfied = true,
   })

assert(unchanged.kind == "shell")
assert(unchanged.status == "not-executed")
assert(unchanged.eligible == false)
assert(unchanged.reversible == false)

local unsafe =
   ShellCompensationMetadata.complete({
      runtime = "grimoire-shell",
      destination = "/tmp/unsafe",
      executed = true,
      changed = true,

      compensation = {
         kind = "filesystem",
         status = "unsafe",
         eligible = false,
         reversible = false,
         reason = "overwrite non sauvegardé",
      },
   })

assert(unsafe.status == "unsafe")
assert(unsafe.reversible == false)

print("")
print(
   "RC4-B3 OK : les mutations Shell exposent "
      .. "une compensation explicite."
)
