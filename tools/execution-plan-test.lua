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
    "== ExecutionPlan RC4-D10A3 Test =="
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
    hypr_activation = 0,
}

local actions =
    execution_plan:getActions()

assert(type(actions) == "table")
assert(#actions == 19)
assert(execution_plan:countActions() == 19)

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
assert(counts.hypr_activation == 1)

assert(actions[1].type == "command")
assert(actions[8].type == "shell_operation")

assert(
    actions[19].type
        == "hypr_activation"
)

assert(
    actions[19].manager == "deploy"
)

assert(
    actions[19].name == "activate-hypr"
)

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
    "RC4-D10A3 OK : le plan contient "
        .. "19 actions, dont l’activation Hypr "
        .. "en dernière position."
)
