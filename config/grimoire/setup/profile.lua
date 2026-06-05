local Profile = {}

local Profiles = require("packaging.profiles")

local profiles = {
    beginner = {
        id = "beginner",
        label = "Beginner",
        description = "Découverte de Grimoire",
    },

    advanced = {
        id = "advanced",
        label = "Advanced",
        description = "Utilisateur Linux expérimenté",
    },

    custom = {
        id = "custom",
        label = "Custom",
        description = "Je choisis tout",
    },
}

function Profile.select()
    print("")
    print("===================================")
    print("        Choix du profil")
    print("===================================")
    print("")

    print("1 - Beginner")
    print("    Découverte de Grimoire")
    print("")

    print("2 - Advanced")
    print("    Utilisateur Linux expérimenté")
    print("")

    print("3 - Custom")
    print("    Je choisis tout")
    print("")

    io.write("Choix [1] : ")

    local input = io.read()

    if input == "" or input == nil then
        return "beginner"
    end

    if input == "1" then
        return "beginner"
    elseif input == "2" then
        return "advanced"
    elseif input == "3" then
        return "custom"
    end

    print("")
    print("Choix invalide.")
    print("Profil Beginner sélectionné.")
    print("")

    return "beginner"
end

function Profile.load(profile_name)
    local profile = Profiles[profile_name]

    if not profile then
        error("Unknown profile: " .. tostring(profile_name))
    end

    return profile
end

return Profile
