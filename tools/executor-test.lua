package.path = "./?.lua;./?/init.lua;" .. package.path

local Builder = require("installer.builder")
local ExecutionPlanBuilder = require("installer.execution_plan_builder")
local Executor = require("installer.executor")

print("== Executor RC2-01 Test ==")

local installation_plan = Builder.build("gibeytech")
local execution_plan = ExecutionPlanBuilder.build(installation_plan, {
    dry_run = true,
})

local result = Executor.execute(execution_plan, {
    dry_run = true,
})

assert(result.ok == true)
assert(result.dry_run == true)
assert(result.mode == "dry-run")
assert(type(result.results) == "table")
assert(#result.results == execution_plan:countActions())
assert(result.executed_actions == 0)

assert(result.results[1].manager == "packages")
assert(result.results[1].details.runner.prepared == true)
assert(result.results[1].details.runner.simulated == true)
assert(result.results[1].details.runner.executed == false)

print("")
print("Actions exécutées : " .. tostring(#result.results))
print("Mode              : " .. tostring(result.mode))

print("")
print("RC2-01 OK : Executor exécute un ExecutionPlan normalisé.")
