package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ServiceRollback = require(
   "installer.service_rollback"
)

print(
   "== ServiceRollback RC4-A3 Contract Test =="
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

local function write_file(path, content)
   local file = assert(io.open(path, "wb"))

   assert(file:write(content))
   assert(file:close())
end

local function read_file(path)
   local file = assert(io.open(path, "rb"))
   local content = assert(file:read("*a"))

   assert(file:close())

   return content
end

local function read_state(path)
   return read_file(path):match(
      "^%s*(.-)%s*$"
   )
end

local temporary_directory = os.tmpname()

os.remove(temporary_directory)

assert(command_succeeded(
   "mkdir -p -- "
      .. shell_quote(temporary_directory)
))

local state_path =
   temporary_directory .. "/state"

local fake_systemctl =
   temporary_directory .. "/systemctl"

write_file(state_path, "enabled\n")

write_file(
   fake_systemctl,
   table.concat({
      "#!/bin/sh",
      "set -eu",
      "state_file=" .. shell_quote(state_path),
      "",
      "if [ \"${1-}\" = \"--user\" ]; then",
      "    shift",
      "fi",
      "",
      "command=\"${1-}\"",
      "shift",
      "",
      "case \"$command\" in",
      "    show)",
      "        state=\"$(cat \"$state_file\")\"",
      "        printf '%s\\n' \\",
      "            'LoadState=loaded' \\",
      "            \"UnitFileState=$state\"",
      "        ;;",
      "    enable)",
      "        printf '%s\\n' enabled > \"$state_file\"",
      "        ;;",
      "    disable)",
      "        printf '%s\\n' disabled > \"$state_file\"",
      "        ;;",
      "    *)",
      "        exit 64",
      "        ;;",
      "esac",
      "",
   }, "\n")
)

assert(command_succeeded(
   "chmod 700 -- "
      .. shell_quote(fake_systemctl)
))

local metadata = {
   kind = "service",
   status = "ready",
   eligible = true,
   reversible = true,
   compensation_type =
      "restore-service-state",
   service = "demo.service",
   unit = "demo.service",
   scope = "system",
   operation = "enable",
   restore_operation = "disable",
   load_state_before = "loaded",
   unit_file_state_before = "disabled",
   load_state_after = "loaded",
   unit_file_state_after = "enabled",
   systemctl_path = fake_systemctl,
   sudo_path = nil,
   elevated = false,
   timeout_seconds = 2,
   kill_after_seconds = 1,
}

local dry_run =
   ServiceRollback.run(
      metadata,
      {
         dry_run = true,
      }
   )

assert(dry_run.ok == true)
assert(dry_run.status == "simulated")
assert(dry_run.executed == false)
assert(read_state(state_path) == "enabled")

local restored =
   ServiceRollback.run(
      metadata,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(restored.ok == true)
assert(restored.status == "restored")
assert(restored.executed == true)
assert(restored.restored == true)
assert(restored.already_restored == false)
assert(read_state(state_path) == "disabled")

local already_restored =
   ServiceRollback.run(
      metadata,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(already_restored.ok == true)

assert(
   already_restored.status
      == "already-restored"
)

assert(already_restored.executed == false)
assert(already_restored.restored == true)
assert(already_restored.already_restored == true)

local invalid =
   ServiceRollback.run(
      {
         kind = "service",
      },
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert(invalid.ok == false)
assert(invalid.status == "invalid")
assert(invalid.executed == false)

assert(command_succeeded(
   "rm -rf -- "
      .. shell_quote(
         temporary_directory
      )
))

print("")
print(
   "RC4-A3 OK : ServiceRollback restaure "
      .. "l’état systemd initial de manière idempotente."
)
