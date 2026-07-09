local PackageManager = require("installer.managers.package_manager")
local ServiceManager = require("installer.managers.service_manager")
local DeployManager = require("installer.managers.deploy_manager")
local ShellManager = require("installer.managers.shell_manager")
local AssetManager = require("installer.managers.asset_manager")

local Executor = {}

function Executor.execute(plan)
    PackageManager.install(plan)
    ServiceManager.enable(plan)
    ShellManager.deploy(plan)
    AssetManager.deploy(plan)
    DeployManager.deploy(plan)
end

return Executor
