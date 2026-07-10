local InstallationPlan = {}
InstallationPlan.__index = InstallationPlan

function InstallationPlan:new(data)
    assert(type(data) == "table", "InstallationPlan:new() attend une table.")

    local plan = setmetatable({}, self)

    plan.profile = data.profile or {}

    plan.packages = data.packages or {}
    plan.services = data.services or {}
    plan.shell = data.shell or {}
    plan.theme = data.theme or {}
    plan.assets = data.assets or {}
    plan.robustness = data.robustness or {}
    plan.dotfiles = data.dotfiles or {}

    return plan
end

function InstallationPlan:getProfile()
    return self.profile
end

function InstallationPlan:getPackages()
    return self.packages
end

function InstallationPlan:getServices()
    return self.services
end

function InstallationPlan:getShell()
    return self.shell
end

function InstallationPlan:getTheme()
    return self.theme
end

function InstallationPlan:getAssets()
    return self.assets
end

function InstallationPlan:getRobustness()
    return self.robustness
end

function InstallationPlan:getDotfiles()
    return self.dotfiles
end

return InstallationPlan
