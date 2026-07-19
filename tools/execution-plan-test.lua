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
    "== ExecutionPlan RC4-D9C Test =="
)

local execution_plan =
    ExecutionPlanBuilder.build(
        Builder.build("gibeytech"),
        {
            dry_run = true,
        }
    )

local counts = {
    command = 0,
    service_operation = 0,
    shell_operation = 0,
    file_operation = 0,
}

local actions =
    execution_plan:getActions()

assert(type(actions) == "table")
assert(#actions == 18)
assert(execution_plan:countActions() == 18)

for _, action in ipairs(actions) do
    assert(type(action) == "table")
    assert(type(action.type) == "string")
    assert(type(action.manager) == "string")
    assert(type(action.name) == "string")

    assert(
        counts[action.type] ~= nil,
        "Type d'action inattendu : "
            .. tostring(action.type)
    )

    counts[action.type] =
        counts[action.type] + 1
end

assert(counts.command == 1)
assert(counts.service_operation == 6)
assert(counts.shell_operation == 1)
assert(counts.file_operation == 10)

assert(actions[1].type == "command")
assert(actions[8].type == "shell_operation")

print("")
print(
    "Actions normalisées : "
        .. tostring(#actions)
)

print(
    "Mode                : "
        .. tostring(execution_plan.mode)
)

print("")
print(
    "RC4-D9C OK : le plan contient "
        .. "18 actions, dont 10 filesystem."
)
