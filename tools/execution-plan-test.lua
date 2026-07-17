package.path = "./?.lua;./?/init.lua;" .. package.path

local Builder = require("installer.builder")
local ExecutionPlanBuilder = require("installer.execution_plan_builder")

print("== ExecutionPlan RC1-24 Test ==")

local installation_plan = Builder.build("gibeytech")
local execution_plan = ExecutionPlanBuilder.build(installation_plan, {
    dry_run = true,
})

assert(execution_plan:getMode() == "dry-run")
assert(type(execution_plan:getProfile()) == "table")
assert(type(execution_plan:getActions()) == "table")
assert(execution_plan:countActions() == 12)

print("")
print("Actions normalisées : " .. tostring(execution_plan:countActions()))
print("Mode                : " .. tostring(execution_plan:getMode()))

print("")
print("RC1-24 OK : ExecutionPlan construit depuis InstallationPlan.")
