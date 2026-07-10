local ExecutionResult = require(
    "installer.result.execution_result"
)

local ServiceSpec = require(
    "installer.model.service_spec"
)

local ServiceManager = {}

local function resolve_service_config(plan)
    if type(plan) ~= "table" then
        return nil
    end

    if type(plan.getServices) == "function" then
        return plan:getServices()
    end

    return plan.services
end

local function collect_services(config)
    local definitions, errors =
        ServiceSpec.collect(config)

    local result = {
        enabled = {},
        disabled = {},
        definitions = definitions,
    }

    for _, definition in ipairs(definitions) do
        if definition.operation == "enable" then
            table.insert(
                result.enabled,
                definition.unit
            )
        elseif definition.operation == "disable" then
            table.insert(
                result.disabled,
                definition.unit
            )
        end
    end

    return result, errors
end

local function print_definition(prefix, definition)
    print(
        "  "
            .. tostring(prefix)
            .. " ["
            .. tostring(definition.scope)
            .. "] "
            .. tostring(definition.unit)
    )
end

function ServiceManager.enable(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false

    local services, errors = collect_services(
        resolve_service_config(plan)
    )

    print("[ServiceManager] Préparation des services...")

    if #errors > 0 then
        return ExecutionResult.fail(
            "services",
            "Configuration services invalide",
            {
                dry_run = dry_run,
                actions = 0,
                details = {
                    errors = errors,
                    services = services,
                },
            }
        )
    end

    if options.force_fail_at == "services" then
        return ExecutionResult.fail(
            "services",
            "Erreur forcée pour test RC1-09",
            {
                dry_run = dry_run,
                actions = 0,
                details = {
                    message =
                        "Échec simulé ServiceManager",
                },
            }
        )
    end

    if #services.definitions == 0 then
        print(
            "[ServiceManager] Aucun service à traiter"
        )

        return ExecutionResult.ok("services", {
            dry_run = dry_run,
            actions = 0,
            details = services,
        })
    end

    print("[ServiceManager] Services planifiés :")

    for _, definition in ipairs(
        services.definitions
    ) do
        local prefix =
            definition.operation == "enable"
                and "+"
                or "-"

        print_definition(prefix, definition)
    end

    print("")

    if dry_run then
        print(
            "[ServiceManager] Dry-run : "
                .. "aucune action systemctl exécutée"
        )
    else
        print(
            "[ServiceManager] Apply sécurisé : "
                .. "services préparés mais non modifiés"
        )

        print(
            "[ServiceManager] Action systemctl "
                .. "bloquée pendant RC4-A1"
        )
    end

    return ExecutionResult.ok("services", {
        dry_run = dry_run,
        actions = #services.definitions,
        details = services,
    })
end

return ServiceManager
