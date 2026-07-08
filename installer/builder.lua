local ProfileLoader = require("core.loader.profile_loader")

local Builder = {}

function Builder.build(profile_id)
    local profile = ProfileLoader.load(profile_id)

    local plan = {
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
    }

    return plan
end

return Builder
