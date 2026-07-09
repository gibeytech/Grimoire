local ExecutionResult = require("installer.result.execution_result")

local PackageManager = {}

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

local function collect_packages(plan)
    local packages = {}

    if not plan or not plan.packages or not plan.packages.groups then
        return packages
    end

    for _, group_packages in pairs(plan.packages.groups) do
        for _, package in ipairs(group_packages or {}) do
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
        print("[PackageManager] Exécution réelle non activée en RC1-11")
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
