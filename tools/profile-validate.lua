package.path = "./?.lua;./?/init.lua;" .. package.path

local ProfileLoader = require("core.loader.profile_loader")
local ProfileValidator = require("core.validator.profile_validator")

local profile_id = arg[1] or "gibeytech"

local profile = ProfileLoader.load(profile_id)
local valid, errors = ProfileValidator.validate(profile)

print("== Grimoire V3 — Profile Validate ==")
print("Profil : " .. profile:getName())
print("ID     : " .. profile:getId())
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
print("RC0-14 OK : ProfileValidator valide un objet Profile.")
