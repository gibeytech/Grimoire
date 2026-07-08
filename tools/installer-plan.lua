package.path = "./?.lua;./?/init.lua;" .. package.path

local Builder = require("installer.builder")

local profile_id = arg[1] or "gibeytech"

local plan = Builder.build(profile_id)

print("== Grimoire V3 — Installation Plan ==")
print("")
print("Profil : " .. plan.profile.name)
print("ID     : " .. plan.profile.id)
print("Version: " .. plan.profile.version)
print("Root   : " .. plan.profile.root)
print("")

print("Le Builder consomme l'API publique du Profile :")
print("")

if plan.packages then
    print("✓ Packages")
end

if plan.services then
    print("✓ Services")
end

if plan.shell then
    print("✓ Shell")
end

if plan.theme then
    print("✓ Theme")
end

if plan.assets then
    print("✓ Assets")
end

print("")
print("RC0-12 OK : Builder génère un InstallationPlan.")
