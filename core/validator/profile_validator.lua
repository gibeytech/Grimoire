local ProfileValidator = {}

local REQUIRED_METHODS = {
    "getId",
    "getName",
    "getVersion",
    "getRoot",
    "getPackages",
    "getServices",
    "getShell",
    "getTheme",
    "getAssets",
    "getRobustness",
}

local function add_error(errors, message)
    table.insert(errors, message)
end

function ProfileValidator.validate(profile)
    local errors = {}

    if type(profile) ~= "table" then
        add_error(errors, "Le profil doit être un objet Profile.")
        return false, errors
    end

    for _, method_name in ipairs(REQUIRED_METHODS) do
        if type(profile[method_name]) ~= "function" then
            add_error(errors, "Méthode manquante sur Profile : " .. method_name)
        end
    end

    if #errors > 0 then
        return false, errors
    end

    if not profile:getId() or profile:getId() == "" then
        add_error(errors, "ID du profil manquant.")
    end

    if not profile:getName() or profile:getName() == "" then
        add_error(errors, "Nom du profil manquant.")
    end

    if not profile:getVersion() or profile:getVersion() == "" then
        add_error(errors, "Version du profil manquante.")
    end

    if not profile:getRoot() or profile:getRoot() == "" then
        add_error(errors, "Racine du profil manquante.")
    end

    if type(profile:getPackages()) ~= "table" then
        add_error(errors, "Configuration packages invalide ou absente.")
    end

    if type(profile:getServices()) ~= "table" then
        add_error(errors, "Configuration services invalide ou absente.")
    end

    if type(profile:getShell()) ~= "table" then
        add_error(errors, "Configuration shell invalide ou absente.")
    end

    if type(profile:getTheme()) ~= "table" then
        add_error(errors, "Configuration theme invalide ou absente.")
    end

    if type(profile:getAssets()) ~= "table" then
        add_error(errors, "Configuration assets invalide ou absente.")
    end

    if type(profile:getRobustness()) ~= "table" then
        add_error(errors, "Configuration robustness invalide ou absente.")
    end

    return #errors == 0, errors
end

return ProfileValidator
