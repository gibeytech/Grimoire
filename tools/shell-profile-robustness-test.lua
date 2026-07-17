package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local Builder = require(
   "installer.builder"
)

local ExecutionPlanBuilder = require(
   "installer.execution_plan_builder"
)

print(
   "== Shell Profile RC4-B4 Robustness Test =="
)

local plan =
   Builder.build("gibeytech")

local robustness =
   plan:getRobustness()

assert(type(robustness.shell) == "table")
assert(robustness.shell.timeout_seconds == 120)
assert(robustness.shell.kill_after_seconds == 5)
assert(robustness.shell.retry == false)

local execution_plan =
   ExecutionPlanBuilder.build(
      plan,
      {
         dry_run = true,
      }
   )

local shell_action = nil

for _, action in ipairs(
   execution_plan:getActions()
) do
   if action.type == "shell_operation" then
      shell_action = action
      break
   end
end

assert(type(shell_action) == "table")
assert(shell_action.timeout_seconds == 120)
assert(shell_action.kill_after_seconds == 5)
assert(shell_action.retry == false)

print("")
print(
   "RC4-B4 OK : le plan Shell reçoit "
      .. "sa politique de robustesse."
)
