local PackageManager = require("installer.managers.package_manager")
local ServiceManager = require("installer.managers.service_manager")
local DeployManager = require("installer.managers.deploy_manager")
local ShellManager = require("installer.managers.shell_manager")
local AssetManager = require("installer.managers.asset_manager")

local Executor = {}

function Executor.run(plan, options)
    options = options or {}

    print("== Grimoire V3 Executor ==")

    PackageManager.install(plan, {
        dry_run = options.dry_run ~= false,
    })

    ServiceManager.enable(plan, options)
    ShellManager.deploy(plan, options)
    AssetManager.deploy(plan, options)
    DeployManager.deploy(plan, options)

    return true
end

function Executor.execute(plan, options)
    return Executor.run(plan, options)
end

return Executor
