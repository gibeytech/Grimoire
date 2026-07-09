local ExecutionResult = require("installer.result.execution_result")

local ServiceManager = {}

local function collect_services(services)
    local result = {
        enabled = {},
        disabled = {},
    }

    if not services then
        return result
    end

    for _, service in ipairs(services.enabled or {}) do
        table.insert(result.enabled, service)
    end

    for _, service in ipairs(services.disabled or {}) do
        table.insert(result.disabled, service)
    end

    return result
end

function ServiceManager.enable(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false
    local services = collect_services(plan and plan.services)

    print("[ServiceManager] Activation des services...")

    if options.force_fail_at == "services" then
        return ExecutionResult.fail("services", "Erreur forcée pour test RC1-09", {
            dry_run = dry_run,
            actions = 0,
            details = {
                message = "Échec simulé ServiceManager",
            },
        })
    end

    if #services.enabled == 0 and #services.disabled == 0 then
        print("[ServiceManager] Aucun service à traiter")

        return ExecutionResult.ok("services", {
            dry_run = dry_run,
            actions = 0,
            details = services,
        })
    end

    if #services.enabled > 0 then
        print("[ServiceManager] Services à activer :")

        for _, service in ipairs(services.enabled) do
            print("  + " .. service)
        end
    end

    if #services.disabled > 0 then
        print("[ServiceManager] Services à désactiver :")

        for _, service in ipairs(services.disabled) do
            print("  - " .. service)
        end
    end

    if dry_run then
        print("")
        print("[ServiceManager] Dry-run : aucune action systemctl exécutée")
    else
        print("")
        print("[ServiceManager] Mode réel demandé")
        print("[ServiceManager] Exécution réelle non activée en RC1-13")
    end

    return ExecutionResult.ok("services", {
        dry_run = dry_run,
        actions = #services.enabled + #services.disabled,
        details = services,
    })
end

return ServiceManager
