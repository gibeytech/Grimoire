package.path = "./?.lua;./?/init.lua;" .. package.path

local ExecutionPlan = require("installer.model.execution_plan")
local Executor = require("installer.executor")

print("== Executor RC2-01 Error Test ==")

local execution_plan = ExecutionPlan:new({
    profile = {
        id = "test",
        name = "Test",
    },
    mode = "dry-run",
    actions = {
        {
            type = "command",
            manager = "packages",
            name = "valid-command",
            command = "echo valid",
            executed = false,
        },
        {
            type = "unknown_action",
            manager = "services",
            name = "invalid-action",
            executed = false,
        },
    },
})

local result = Executor.execute(execution_plan, {
    dry_run = true,
})

assert(result.ok == false)
assert(result.dry_run == true)
assert(result.mode == "dry-run")
assert(result.failed_at == "services")
assert(result.error == "Type d'action inconnu: unknown_action")
assert(type(result.results) == "table")
assert(#result.results == 2)

assert(result.results[1].manager == "packages")
assert(result.results[1].ok == true)
assert(result.results[1].details.runner.prepared == true)
assert(result.results[1].details.runner.simulated == true)
assert(result.results[1].details.runner.executed == false)

assert(result.results[2].manager == "services")
assert(result.results[2].ok == false)

print("")
print("RC2-01 OK : Executor stoppe proprement sur une action invalide.")
