local ExecutionResult = require("installer.result.execution_result")
local FileOperations = require("installer.file_operations")

local DeployManager = {}

local function join_path(left, right)
    if not left or left == "" then
        return right
    end

    if not right or right == "" then
        return left
    end

    if string.sub(left, -1) == "/" then
        return left .. right
    end

    return left .. "/" .. right
end

local function collect_deployments(plan)
    local deployments = {}

    if not plan then
        return deployments
    end

    local profile = plan.profile or {}
    local dotfiles = plan.dotfiles or {}

    if dotfiles.source then
        table.insert(deployments, {
            name = "dotfiles",
            type = "symlink",
            source = join_path(profile.root, dotfiles.source),
            destination = "~/.config",
        })
    end

    return deployments
end

local function build_operation(deployment)
    return {
        type = deployment.type,
        name = deployment.name,
        source = deployment.source,
        destination = deployment.destination,
    }
end

function DeployManager.deploy(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false
    local deployments = collect_deployments(plan)
    local operations = {}

    print("[DeployManager] Déploiement des configurations...")

    if #deployments == 0 then
        print("[DeployManager] Aucun déploiement à traiter")

        return ExecutionResult.ok("deploy", {
            dry_run = dry_run,
            actions = 0,
            details = {
                deployments = {},
                operations = {},
            },
        })
    end

    print("[DeployManager] Déploiements à préparer :")

    for _, deployment in ipairs(deployments) do
        print("  - " .. deployment.name .. " : " .. deployment.source .. " -> " .. deployment.destination)

        local operation = build_operation(deployment)
        local operation_result = FileOperations.run(operation, options)

        if not operation_result.ok then
            return ExecutionResult.fail("deploy", operation_result.error, {
                dry_run = dry_run,
                actions = 0,
                details = {
                    deployments = deployments,
                    operations = operations,
                },
            })
        end

        table.insert(operations, operation_result)
    end

    return ExecutionResult.ok("deploy", {
        dry_run = dry_run,
        actions = #deployments,
        details = {
            deployments = deployments,
            operations = operations,
        },
    })
end

return DeployManager
