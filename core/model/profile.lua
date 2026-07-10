local Profile = {}
Profile.__index = Profile

function Profile:new(data)
    assert(type(data) == "table", "Profile:new() attend une table.")

    local profile = setmetatable({}, self)

    profile.id = data.id
    profile.name = data.name
    profile.version = data.version
    profile.description = data.description
    profile.root = data.root

    profile.manifest = data.manifest or {}
    profile.config = data.config or {}

    return profile
end

function Profile:getId()
    return self.id
end

function Profile:getName()
    return self.name
end

function Profile:getVersion()
    return self.version
end

function Profile:getDescription()
    return self.description
end

function Profile:getRoot()
    return self.root
end

function Profile:getPackages()
    return self.config.packages
end

function Profile:getServices()
    return self.config.services
end

function Profile:getShell()
    return self.config.shell
end

function Profile:getTheme()
    return self.config.theme
end

function Profile:getAssets()
    return self.config.assets
end

function Profile:getRobustness()
    return self.config.robustness
end

function Profile:getDotfiles()
    return self.manifest.dotfiles
end

return Profile
