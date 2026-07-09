package.path = "./?.lua;./?/init.lua;" .. package.path

local Builder = require("installer.builder")
local InstallationPlanValidator = require("installer.validator.installation_plan_validator")

local profile_id = arg[1] or "gibeytech"

local plan = Builder.build(profile_id)
local valid, errors = InstallationPlanValidator.validate(plan)

print("== Grimoire V3 — InstallationPlan Validate ==")

local profile = plan:getProfile()
print("Profil : " .. profile.name)
print("ID     : " .. profile.id)
print("")

if not valid then
    print("Validation échouée :")
    for _, err in ipairs(errors) do
        print("- " .. err)
    end
    os.exit(1)
end

print("Validation : OK")
print("")
print("RC1-03 OK : InstallationPlanValidator valide un InstallationPlan.")
