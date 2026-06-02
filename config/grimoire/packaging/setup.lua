local Setup = {}

local Profiles = require("packaging.profiles")
local Catalogue = require("packaging.catalogue")

function Setup.new(profile)
    local profile_data = Profiles[profile]

    if not profile_data then
        error("Unknown profile: " .. tostring(profile))
    end

    return {
        profile = profile,

        terminal = Catalogue.terminals[profile_data.terminal],
        shell = Catalogue.shells[profile_data.shell],
        browser = Catalogue.browsers[profile_data.browser],
        editor = Catalogue.editors[profile_data.editor],
    }
end

return Setup

