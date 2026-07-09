local ExecutionResult = require("installer.result.execution_result")

local DeployManager = {}

function DeployManager.deploy(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false

    print("[DeployManager] Déploiement des configurations...")

    return ExecutionResult.ok("deploy", {
        dry_run = dry_run,
        actions = 0,
        details = {
            message = "Déploiement des configurations préparé",
        },
    })
end

return DeployManager
