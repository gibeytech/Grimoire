package.path = "./?.lua;./?/init.lua;" .. package.path

local ExecutionPlan = require("installer.model.execution_plan")
local Executor = require("installer.executor")

print("== Executor RC2-B4 Apply-Real Integration Test ==")

local execution_plan = ExecutionPlan:new({
    profile = {
        id = "test",
        name = "Test",
    },
    mode = "apply-real",
    actions = {
        {
            type = "command",
            manager = "packages",
            name = "safe-command",
            command = "true",
            executed = false,
        },
    },
})

local result = Executor.execute(execution_plan, {
    dry_run = false,
    apply_real = true,
})

assert(result.ok == true)
assert(result.dry_run == false)
assert(result.mode == "apply-real")
assert(type(result.results) == "table")
assert(#result.results == 1)
assert(result.executed_actions == 1)

local action_result = result.results[1]

assert(action_result.ok == true)
assert(action_result.manager == "packages")
assert(action_result.command == "true")

assert(type(action_result.details) == "table")
assert(type(action_result.details.runner) == "table")

assert(action_result.details.runner.mode == "apply-real")
assert(action_result.details.runner.prepared == true)
assert(action_result.details.runner.simulated == false)
assert(action_result.details.runner.executed == true)
assert(action_result.details.runner.exit_code == 0)
assert(action_result.details.runner.error == nil)

print("")
print("Mode global       : " .. tostring(result.mode))
print("Actions exécutées : " .. tostring(result.executed_actions))

print("")
print("RC2-B4 OK : Executor expose correctement le mode apply-real.")
