local ExecutionResult = require("installer.result.execution_result")

local AssetManager = {}

local function collect_assets(assets)
    local result = {}

    if not assets then
        return result
    end

    for name, config in pairs(assets) do
        table.insert(result, {
            name = name,
            source = config.source,
            destination = config.destination,
        })
    end

    table.sort(result, function(a, b)
        return a.name < b.name
    end)

    return result
end

function AssetManager.deploy(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false
    local assets = collect_assets(plan and plan.assets)

    print("[AssetManager] Déploiement des assets...")

    if #assets == 0 then
        print("[AssetManager] Aucun asset à traiter")

        return ExecutionResult.ok("assets", {
            dry_run = dry_run,
            actions = 0,
            details = {
                assets = {},
            },
        })
    end

    print("[AssetManager] Assets à préparer :")

    for _, asset in ipairs(assets) do
        local line = "  - " .. asset.name .. " : " .. tostring(asset.source)

        if asset.destination then
            line = line .. " -> " .. asset.destination
        end

        print(line)
    end

    if dry_run then
        print("")
        print("[AssetManager] Dry-run : aucun asset copié")
    else
        print("")
        print("[AssetManager] Apply sécurisé : assets préparés mais non copiés")
        print("[AssetManager] Action système bloquée volontairement en RC1-18")
    end

    return ExecutionResult.ok("assets", {
        dry_run = dry_run,
        actions = #assets,
        details = {
            assets = assets,
        },
    })
end

return AssetManager
