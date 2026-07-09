local ExecutionResult = require("installer.result.execution_result")

local ShellManager = {}

local function collect_shell(shell)
    local result = {
        runtime = nil,
        modules = {},
    }

    if not shell then
        return result
    end

    result.runtime = shell.runtime

    for _, module in ipairs(shell.modules or {}) do
        table.insert(result.modules, module)
    end

    return result
end

function ShellManager.deploy(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false
    local shell = collect_shell(plan and plan.shell)

    print("[ShellManager] Déploiement de Grimoire Shell...")

    if not shell.runtime and #shell.modules == 0 then
        print("[ShellManager] Aucune configuration shell à traiter")

        return ExecutionResult.ok("shell", {
            dry_run = dry_run,
            actions = 0,
            details = shell,
        })
    end

    if shell.runtime then
        print("[ShellManager] Runtime : " .. shell.runtime)
    end

    if #shell.modules > 0 then
        print("[ShellManager] Modules à préparer :")

        for _, module in ipairs(shell.modules) do
            print("  - " .. module)
        end
    end

    if dry_run then
        print("")
        print("[ShellManager] Dry-run : aucun déploiement shell exécuté")
    else
        print("")
        print("[ShellManager] Mode réel demandé")
        print("[ShellManager] Exécution réelle non activée en RC1-14")
    end

    return ExecutionResult.ok("shell", {
        dry_run = dry_run,
        actions = #shell.modules,
        details = shell,
    })
end

return ShellManager
