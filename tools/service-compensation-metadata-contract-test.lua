package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ServiceCompensationMetadata = require(
   "installer.result.service_compensation_metadata"
)

print(
   "== ServiceCompensationMetadata RC4-A3 Contract Test =="
)

local function result(data)
   data = data or {}

   return {
      ok = data.ok ~= false,
      prepared = true,
      executed = data.executed ~= false,
      changed = data.changed ~= false,
      already_satisfied =
         data.already_satisfied == true,
      unit = "demo.service",
      service = "demo.service",
      scope = data.scope or "system",
      operation = data.operation,
      state_before = {
         load_state = "loaded",
         unit_file_state =
            data.state_before,
      },
      state_after = {
         load_state = "loaded",
         unit_file_state =
            data.state_after,
      },
      systemctl_path =
         "/tmp/fake-systemctl",
      sudo_path = "/usr/bin/sudo",
      elevated = data.elevated == true,
      timeout_seconds = 10,
      kill_after_seconds = 2,
   }
end

local enabled =
   ServiceCompensationMetadata.complete(
      result({
         operation = "enable",
         state_before = "disabled",
         state_after = "enabled",
      })
   )

assert(enabled.kind == "service")
assert(enabled.status == "ready")
assert(enabled.eligible == true)
assert(enabled.reversible == true)

assert(
   enabled.compensation_type
      == "restore-service-state"
)

assert(enabled.restore_operation == "disable")
assert(enabled.unit == "demo.service")
assert(enabled.scope == "system")

assert(
   enabled.unit_file_state_before
      == "disabled"
)

assert(
   enabled.unit_file_state_after
      == "enabled"
)

local disabled =
   ServiceCompensationMetadata.complete(
      result({
         operation = "disable",
         state_before = "enabled",
         state_after = "disabled",
      })
   )

assert(disabled.status == "ready")
assert(disabled.restore_operation == "enable")

local already_satisfied =
   ServiceCompensationMetadata.complete(
      result({
         operation = "enable",
         state_before = "enabled",
         state_after = "enabled",
         executed = false,
         changed = false,
         already_satisfied = true,
      })
   )

assert(
   already_satisfied.status
      == "not-required"
)

assert(already_satisfied.reversible == false)

local failed =
   ServiceCompensationMetadata.complete(
      result({
         ok = false,
         operation = "enable",
         state_before = "disabled",
         state_after = nil,
         changed = false,
      })
   )

assert(failed.status == "failed")
assert(failed.reversible == false)

local runtime_state =
   ServiceCompensationMetadata.complete(
      result({
         operation = "disable",
         state_before = "enabled-runtime",
         state_after = "disabled",
      })
   )

assert(runtime_state.status == "unsupported")
assert(runtime_state.reversible == false)

local not_executed =
   ServiceCompensationMetadata.not_executed(
      result({
         operation = "enable",
         state_before = nil,
         state_after = nil,
         executed = false,
         changed = false,
      })
   )

assert(not_executed.status == "not-executed")
assert(not_executed.eligible == false)

print("")
print(
   "RC4-A3 OK : les transitions systemd "
      .. "exactement réversibles produisent "
      .. "des métadonnées de compensation sûres."
)
