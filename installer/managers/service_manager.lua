local ExecutionResult = require("installer.result.execution_result")

local ServiceManager = {}

function ServiceManager.enable(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false

    print("[ServiceManager] Activation des services...")

    return ExecutionResult.ok("services", {
        dry_run = dry_run,
        actions = 0,
        details = {
            message = "Activation des services préparée",
        },
    })
end

return ServiceManager
