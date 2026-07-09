local ProfileLoader = require("core.loader.profile_loader")
local InstallationPlan = require("installer.model.installation_plan")

local Builder = {}

function Builder.build(profile_id)
    local profile = ProfileLoader.load(profile_id)

    return InstallationPlan:new({
        profile = {
            id = profile:getId(),
            name = profile:getName(),
            version = profile:getVersion(),
            root = profile:getRoot(),
        },

        packages = profile:getPackages(),
        services = profile:getServices(),
        shell = profile:getShell(),
        theme = profile:getTheme(),
        assets = profile:getAssets(),
        dotfiles = profile:getDotfiles(),
    })
end

return Builder
