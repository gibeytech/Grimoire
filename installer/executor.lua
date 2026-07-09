local PackageManager = require("installer.managers.package_manager")
local ServiceManager = require("installer.managers.service_manager")
local DeployManager = require("installer.managers.deploy_manager")
local ShellManager = require("installer.managers.shell_manager")
local AssetManager = require("installer.managers.asset_manager")

local Executor = {}

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

    local ok, failed_result

    ok, failed_result = run_step(results, function()
        return PackageManager.install(plan, {
            dry_run = dry_run,
        })
    end)

    if not ok then
        return {
            ok = false,
            dry_run = dry_run,
            failed_at = failed_result.manager,
            results = results,
            error = failed_result.error,
        }
    end

    ok, failed_result = run_step(results, function()
        return ServiceManager.enable(plan, {
            dry_run = dry_run,
        })
    end)

    if not ok then
        return {
            ok = false,
            dry_run = dry_run,
            failed_at = failed_result.manager,
            results = results,
            error = failed_result.error,
        }
    end

    ok, failed_result = run_step(results, function()
        return ShellManager.deploy(plan, {
            dry_run = dry_run,
        })
    end)

    if not ok then
        return {
            ok = false,
            dry_run = dry_run,
            failed_at = failed_result.manager,
            results = results,
            error = failed_result.error,
        }
    end

    ok, failed_result = run_step(results, function()
        return AssetManager.deploy(plan, {
            dry_run = dry_run,
        })
    end)

    if not ok then
        return {
            ok = false,
            dry_run = dry_run,
            failed_at = failed_result.manager,
            results = results,
            error = failed_result.error,
        }
    end

    ok, failed_result = run_step(results, function()
        return DeployManager.deploy(plan, {
            dry_run = dry_run,
        })
    end)

    if not ok then
        return {
            ok = false,
            dry_run = dry_run,
            failed_at = failed_result.manager,
            results = results,
            error = failed_result.error,
        }
    end

    return {
        ok = true,
        dry_run = dry_run,
        results = results,
    }
end

function Executor.execute(plan, options)
    return Executor.run(plan, options)
end

return Executor
