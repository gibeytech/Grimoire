local ExecutionResult = require("installer.result.execution_result")

local PackageManager = {}

local DEFAULT_GROUP_ORDER = {
    "base",
    "desktop",
    "development",
    "multimedia",
    "graphics",
}

local function unique_packages(packages)
    local seen = {}
    local result = {}

    for _, package in ipairs(packages or {}) do
        if not seen[package] then
            seen[package] = true
            table.insert(result, package)
        end
    end

    return result
end

local function contains(values, target)
    for _, value in ipairs(values or {}) do
        if value == target then
            return true
        end
    end

    return false
end

local function sorted_unknown_groups(groups)
    local unknown = {}

    for group_name, _ in pairs(groups or {}) do
        if not contains(DEFAULT_GROUP_ORDER, group_name) then
            table.insert(unknown, group_name)
        end
    end

    table.sort(unknown)

    return unknown
end

local function ordered_group_names(groups)
    local ordered = {}

    for _, group_name in ipairs(DEFAULT_GROUP_ORDER) do
        if groups[group_name] ~= nil then
            table.insert(ordered, group_name)
        end
    end

    for _, group_name in ipairs(sorted_unknown_groups(groups)) do
        table.insert(ordered, group_name)
    end

    return ordered
end

local function collect_packages(plan)
    local packages = {}

    if not plan or not plan.packages or not plan.packages.groups then
        return packages
    end

    local groups = plan.packages.groups

    for _, group_name in ipairs(ordered_group_names(groups)) do
        for _, package in ipairs(groups[group_name] or {}) do
            table.insert(packages, package)
        end
    end

    return unique_packages(packages)
end

function PackageManager.build_pacman_command(packages)
    if not packages or #packages == 0 then
        return nil
    end

    return "sudo pacman -S --needed " .. table.concat(packages, " ")
end

function PackageManager.install(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false
    local packages = collect_packages(plan)
    local command = PackageManager.build_pacman_command(packages)

    print("[PackageManager] Installation des packages")

    if #packages == 0 then
        print("[PackageManager] Aucun package à installer")

        return ExecutionResult.ok("packages", {
            dry_run = dry_run,
            actions = 0,
            command = nil,
            details = {
                packages = {},
            },
        })
    end

    print("[PackageManager] Packages détectés :")

    for _, package in ipairs(packages) do
        print("  - " .. package)
    end

    if dry_run then
        print("")
        print("[PackageManager] Dry-run : commande préparée")
        print(command)
    else
        print("")
        print("[PackageManager] Mode réel demandé")
        print("[PackageManager] Exécution réelle non activée en RC1-12")
        print("[PackageManager] Commande préparée :")
        print(command)
    end

    return ExecutionResult.ok("packages", {
        dry_run = dry_run,
        actions = #packages,
        command = command,
        details = {
            packages = packages,
        },
    })
end

return PackageManager
