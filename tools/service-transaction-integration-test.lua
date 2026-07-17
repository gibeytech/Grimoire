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
   "== ServiceTransaction RC4-A3 Integration Test =="
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

local function read_state(path)
   local file = assert(io.open(path, "rb"))
   local content = assert(file:read("*a"))

   assert(file:close())

   return content:match("^%s*(.-)%s*$")
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

write_file(state_path, "disabled\n")

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

local plan = ExecutionPlan:new({
   profile = {
      id = "rc4-a3-service-transaction",
   },
   mode = "apply-real",
   actions = {
      {
         type = "service_operation",
         manager = "services",
         name = "enable-service",
         unit = "demo.service",
         service = "demo.service",
         operation = "enable",
         scope = "system",
      },
      {
         type = "command",
         manager = "packages",
         name = "forced-failure",
         command = "false",
      },
   },
})

local execution =
   Executor.execute(
      plan,
      {
         dry_run = false,
         apply_real = true,
         systemctl_path = fake_systemctl,
         elevate_system = false,
      }
   )

assert(execution.ok == false)

assert(
   execution.transaction_status
      == "rolled-back"
)

assert(execution.failed_at == "packages")
assert(execution.executed_actions == 2)
assert(#execution.results == 2)
assert(#execution.journal == 2)

assert(
   execution
      .journal[1]
      .compensation
      .kind
      == "service"
)

assert(
   execution
      .journal[1]
      .compensation
      .status
      == "ready"
)

assert(
   execution
      .journal[1]
      .compensation
      .restore_operation
      == "disable"
)

assert(
   execution.journal[2].compensation
      == nil
)

assert(execution.rollback.attempted == true)
assert(execution.rollback.ok == true)

assert(
   execution.rollback.status
      == "completed"
)

assert(execution.rollback.total_actions == 1)
assert(execution.rollback.successful_actions == 1)
assert(execution.rollback.failed_actions == 0)
assert(execution.rollback.executed_actions == 1)
assert(#execution.rollback.results == 1)

local rollback =
   execution.rollback.results[1]

assert(rollback.manager == "services")
assert(rollback.name == "enable-service")
assert(rollback.ok == true)
assert(rollback.status == "restored")

assert(
   rollback.compensation.kind
      == "service"
)

assert(
   rollback.result.restored == true
)

assert(read_state(state_path) == "disabled")

assert(command_succeeded(
   "rm -rf -- "
      .. shell_quote(
         temporary_directory
      )
))

print("")
print(
   "RC4-A3 OK : un échec suivant restaure "
      .. "automatiquement l’état systemd antérieur."
)
