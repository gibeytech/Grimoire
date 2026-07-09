local ExecutionResult = require("installer.result.execution_result")

local AssetManager = {}

function AssetManager.deploy(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false

    print("[AssetManager] Déploiement des assets...")

    return ExecutionResult.ok("assets", {
        dry_run = dry_run,
        actions = 0,
        details = {
            message = "Déploiement des assets préparé",
        },
    })
end

return AssetManager
