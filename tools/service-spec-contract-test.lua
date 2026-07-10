package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local ServiceSpec = require(
    "installer.model.service_spec"
)

local Builder = require(
    "installer.builder"
)

local ExecutionPlanBuilder = require(
    "installer.execution_plan_builder"
)

print("== ServiceSpec RC4-A1 Contract Test ==")

local definitions, errors =
    ServiceSpec.collect({
        services = {
            {
                unit = "NetworkManager.service",
                operation = "enable",
                scope = "system",
            },
            {
                unit = "wireplumber.service",
                operation = "enable",
                scope = "user",
            },
            {
                unit = "sshd.service",
                operation = "disable",
                scope = "system",
            },
        },
    })

assert(type(definitions) == "table")
assert(type(errors) == "table")
assert(#errors == 0)
assert(#definitions == 3)

assert(
    definitions[1].unit
        == "NetworkManager.service"
)

assert(
    definitions[1].service
        == "NetworkManager.service"
)

assert(definitions[1].operation == "enable")
assert(definitions[1].scope == "system")

assert(
    definitions[2].unit
        == "wireplumber.service"
)

assert(definitions[2].scope == "user")
assert(definitions[3].operation == "disable")

local legacy_definitions, legacy_errors =
    ServiceSpec.collect({
        enabled = {
            "NetworkManager",
            "bluetooth",
        },
        disabled = {
            "sshd",
        },
    })

assert(#legacy_errors == 0)
assert(#legacy_definitions == 3)
assert(legacy_definitions[1].scope == "system")
assert(legacy_definitions[1].operation == "enable")
assert(legacy_definitions[3].operation == "disable")

local _, invalid_scope_errors =
    ServiceSpec.collect({
        services = {
            {
                unit = "invalid.service",
                operation = "enable",
                scope = "session",
            },
        },
    })

assert(#invalid_scope_errors == 1)

local _, invalid_operation_errors =
    ServiceSpec.collect({
        services = {
            {
                unit = "invalid.service",
                operation = "restart",
                scope = "system",
            },
        },
    })

assert(#invalid_operation_errors == 1)

local _, duplicate_errors =
    ServiceSpec.collect({
        services = {
            {
                unit = "duplicate.service",
                operation = "enable",
                scope = "system",
            },
            {
                unit = "duplicate.service",
                operation = "disable",
                scope = "system",
            },
        },
    })

assert(#duplicate_errors == 1)

local installation_plan =
    Builder.build("gibeytech")

local execution_plan =
    ExecutionPlanBuilder.build(
        installation_plan,
        {
            dry_run = true,
        }
    )

local service_actions = {}

for _, action in ipairs(
    execution_plan:getActions()
) do
    if action.type == "service_operation" then
        table.insert(service_actions, action)
    end
end

assert(#service_actions == 6)

local expected = {
    ["NetworkManager.service"] = {
        operation = "enable",
        scope = "system",
    },
    ["bluetooth.service"] = {
        operation = "enable",
        scope = "system",
    },
    ["pipewire.service"] = {
        operation = "enable",
        scope = "user",
    },
    ["wireplumber.service"] = {
        operation = "enable",
        scope = "user",
    },
    ["sddm.service"] = {
        operation = "enable",
        scope = "system",
    },
    ["sshd.service"] = {
        operation = "disable",
        scope = "system",
    },
}

for _, action in ipairs(service_actions) do
    local contract = expected[action.unit]

    assert(
        contract ~= nil,
        "Action service inattendue : "
            .. tostring(action.unit)
    )

    assert(action.service == action.unit)

    assert(
        action.operation
            == contract.operation
    )

    assert(action.scope == contract.scope)
    assert(
        action.name
            == contract.operation
                .. "-service"
    )
end

print("")
print(
    "RC4-A1 OK : les services sont normalisés "
        .. "avec unité, opération et scope explicites."
)
