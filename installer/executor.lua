local PackageManager = require("installer.managers.package_manager")
local ServiceManager = require("installer.managers.service_manager")
local DeployManager = require("installer.managers.deploy_manager")
local ShellManager = require("installer.managers.shell_manager")
local AssetManager = require("installer.managers.asset_manager")

local Executor = {}

local function execution_mode(dry_run)
    if dry_run then
        return "dry-run"
    end

    return "apply-safe"
end

local function failure_result(dry_run, failed_result, results)
    return {
        ok = false,
        dry_run = dry_run,
        mode = execution_mode(dry_run),
        failed_at = failed_result.manager,
        results = results,
        error = failed_result.error,
        executed_actions = 0,
    }
end

local function run_step(results, step)
    local result = step()

    table.insert(results, result)

    if not result.ok then
        return false, result
    end

    return true, result
end

function Executor.run(plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false
    local results = {}

    print("== Grimoire V3 Executor ==")

    if dry_run then
        print("[Executor] Mode dry-run actif")
    else
        print("[Executor] Mode apply sécurisé actif")
        print("[Executor] Aucune action système réelle ne sera exécutée en RC1-21")
    end

    local ok, failed_result

    ok, failed_result = run_step(results, function()
        return PackageManager.install(plan, options)
    end)

    if not ok then
        return failure_result(dry_run, failed_result, results)
    end

    ok, failed_result = run_step(results, function()
        return ServiceManager.enable(plan, options)
    end)

    if not ok then
        return failure_result(dry_run, failed_result, results)
    end

    ok, failed_result = run_step(results, function()
        return ShellManager.deploy(plan, options)
    end)

    if not ok then
        return failure_result(dry_run, failed_result, results)
    end

    ok, failed_result = run_step(results, function()
        return AssetManager.deploy(plan, options)
    end)

    if not ok then
        return failure_result(dry_run, failed_result, results)
    end

    ok, failed_result = run_step(results, function()
        return DeployManager.deploy(plan, options)
    end)

    if not ok then
        return failure_result(dry_run, failed_result, results)
    end

    return {
        ok = true,
        dry_run = dry_run,
        mode = execution_mode(dry_run),
        results = results,
        executed_actions = 0,
    }
end

function Executor.execute(plan, options)
    return Executor.run(plan, options)
end

return Executor
