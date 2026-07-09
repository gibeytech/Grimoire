local ExecutionResult = require("installer.result.execution_result")

local ShellManager = {}

function ShellManager.deploy(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false

    print("[ShellManager] Déploiement de Grimoire Shell...")

    return ExecutionResult.ok("shell", {
        dry_run = dry_run,
        actions = 0,
        details = {
            message = "Déploiement de Grimoire Shell préparé",
        },
    })
end

return ShellManager
