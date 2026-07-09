local ExecutionResult = require("installer.result.execution_result")
local FileOperations = require("installer.file_operations")

local AssetManager = {}

local function collect_assets(assets)
    local result = {}

    if not assets then
        return result
    end

    for name, config in pairs(assets) do
        table.insert(result, {
            name = name,
            type = "copy",
            source = config.source,
            destination = config.destination,
        })
    end

    table.sort(result, function(a, b)
        return a.name < b.name
    end)

    return result
end

local function build_operation(asset)
    return {
        type = asset.type,
        name = asset.name,
        source = asset.source,
        destination = asset.destination,
    }
end

function AssetManager.deploy(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false
    local assets = collect_assets(plan and plan.assets)
    local operations = {}

    print("[AssetManager] Déploiement des assets...")

    if #assets == 0 then
        print("[AssetManager] Aucun asset à traiter")

        return ExecutionResult.ok("assets", {
            dry_run = dry_run,
            actions = 0,
            details = {
                assets = {},
                operations = {},
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

        local operation = build_operation(asset)
        local operation_result = FileOperations.run(operation, options)

        if not operation_result.ok then
            return ExecutionResult.fail("assets", operation_result.error, {
                dry_run = dry_run,
                actions = 0,
                details = {
                    assets = assets,
                    operations = operations,
                },
            })
        end

        table.insert(operations, operation_result)
    end

    return ExecutionResult.ok("assets", {
        dry_run = dry_run,
        actions = #assets,
        details = {
            assets = assets,
            operations = operations,
        },
    })
end

return AssetManager
