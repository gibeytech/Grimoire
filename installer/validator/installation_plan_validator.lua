local InstallationPlanValidator = {}

local REQUIRED_METHODS = {
    "getProfile",
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

function InstallationPlanValidator.validate(plan)
    local errors = {}

    if type(plan) ~= "table" then
        add_error(errors, "Le plan doit être un objet InstallationPlan.")
        return false, errors
    end

    for _, method_name in ipairs(REQUIRED_METHODS) do
        if type(plan[method_name]) ~= "function" then
            add_error(errors, "Méthode manquante sur InstallationPlan : " .. method_name)
        end
    end

    if #errors > 0 then
        return false, errors
    end

    local profile = plan:getProfile()

    if type(profile) ~= "table" then
        add_error(errors, "Le profil du plan est invalide.")
    else
        if not profile.id or profile.id == "" then
            add_error(errors, "ID du profil manquant dans le plan.")
        end

        if not profile.name or profile.name == "" then
            add_error(errors, "Nom du profil manquant dans le plan.")
        end

        if not profile.version or profile.version == "" then
            add_error(errors, "Version du profil manquante dans le plan.")
        end
    end

    if type(plan:getPackages()) ~= "table" then
        add_error(errors, "Packages invalides dans le plan.")
    end

    if type(plan:getServices()) ~= "table" then
        add_error(errors, "Services invalides dans le plan.")
    end

    if type(plan:getShell()) ~= "table" then
        add_error(errors, "Shell invalide dans le plan.")
    end

    if type(plan:getTheme()) ~= "table" then
        add_error(errors, "Theme invalide dans le plan.")
    end

    if type(plan:getAssets()) ~= "table" then
        add_error(errors, "Assets invalides dans le plan.")
    end

    if type(plan:getRobustness()) ~= "table" then
        add_error(errors, "Politiques de robustesse invalides dans le plan.")
    end

    return #errors == 0, errors
end

return InstallationPlanValidator
