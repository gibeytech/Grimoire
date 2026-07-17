package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local Builder = require(
   "installer.builder"
)

local ExecutionPlanBuilder = require(
   "installer.execution_plan_builder"
)

local ServiceExecutor = require(
   "installer.service_executor"
)

print(
   "== Service Profile RC4-A4 Robustness Test =="
)

local installation_plan =
   Builder.build("gibeytech")

local robustness =
   installation_plan:getRobustness()

assert(type(robustness) == "table")
assert(type(robustness.services) == "table")
assert(robustness.services.timeout_seconds == 30)
assert(robustness.services.kill_after_seconds == 5)
assert(robustness.services.retry == false)

local execution_plan =
   ExecutionPlanBuilder.build(
      installation_plan,
      {
         dry_run = true,
      }
   )

local service_count = 0

for _, action in ipairs(
   execution_plan:getActions()
) do
   if action.type == "service_operation" then
      service_count = service_count + 1

      assert(action.timeout_seconds == 30)
      assert(action.kill_after_seconds == 5)
      assert(action.retry == false)
      assert(
         action.scope == "system"
            or action.scope == "user"
      )
   end
end

assert(service_count == 6)

local missing_disabled =
   ServiceExecutor.execute(
      {
         unit = "grimoire-missing.service",
         operation = "disable",
         scope = "system",
      },
      {
         systemctl_path =
            "/usr/bin/systemctl",
         elevate_system = false,
         timeout_seconds = 10,
         kill_after_seconds = 2,
      }
   )

if missing_disabled.ok then
   assert(missing_disabled.executed == false)

   assert(
      missing_disabled.reason
         == "already-absent"
      or missing_disabled.reason
         == "already-satisfied"
   )
end

print("")
print(
   "RC4-A4 OK : les services du profil "
      .. "reçoivent leurs politiques de robustesse."
)
