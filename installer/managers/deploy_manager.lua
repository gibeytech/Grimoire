local ExecutionResult = require("installer.result.execution_result")

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
            source = join_path(profile.root, dotfiles.source),
            destination = "~/.config",
        })
    end

    return deployments
end

function DeployManager.deploy(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false
    local deployments = collect_deployments(plan)

    print("[DeployManager] Déploiement des configurations...")

    if #deployments == 0 then
        print("[DeployManager] Aucun déploiement à traiter")

        return ExecutionResult.ok("deploy", {
            dry_run = dry_run,
            actions = 0,
            details = {
                deployments = {},
            },
        })
    end

    print("[DeployManager] Déploiements à préparer :")

    for _, deployment in ipairs(deployments) do
        print("  - " .. deployment.name .. " : " .. deployment.source .. " -> " .. deployment.destination)
    end

    if dry_run then
        print("")
        print("[DeployManager] Dry-run : aucune configuration copiée")
    else
        print("")
        print("[DeployManager] Apply sécurisé : dotfiles préparés mais non liés")
        print("[DeployManager] Action système bloquée volontairement en RC1-19")
    end

    return ExecutionResult.ok("deploy", {
        dry_run = dry_run,
        actions = #deployments,
        details = {
            deployments = deployments,
        },
    })
end

return DeployManager
