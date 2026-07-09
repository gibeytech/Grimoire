local ExecutionResult = require("installer.result.execution_result")
local CommandRunner = require("installer.command_runner")

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

PackageManager.collect_packages = collect_packages
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
                runner = nil,
            },
        })
    end

    print("[PackageManager] Packages détectés :")

    for _, package in ipairs(packages) do
        print("  - " .. package)
    end

    print("")

    local runner_result = CommandRunner.run(command, options)

    if not runner_result.ok then
        return ExecutionResult.fail("packages", runner_result.error, {
            dry_run = dry_run,
            actions = 0,
            command = command,
            details = {
                packages = packages,
                runner = runner_result,
            },
        })
    end

    return ExecutionResult.ok("packages", {
        dry_run = dry_run,
        actions = #packages,
        command = command,
        details = {
            packages = packages,
            runner = runner_result,
        },
    })
end

return PackageManager
