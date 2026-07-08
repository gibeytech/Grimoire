package.path = "./?.lua;./?/init.lua;" .. package.path

local ProfileLoader = require("core.loader.profile_loader")

local profile_id = arg[1] or "gibeytech"
local profile = ProfileLoader.load(profile_id)

assert(type(profile.getId) == "function", "ProfileLoader ne retourne pas un objet Profile.")
assert(type(profile.getPackages) == "function", "ProfileLoader ne retourne pas un objet Profile.")

print("== Grimoire V3 — Profile Inspect ==")
print("ID          : " .. profile:getId())
print("Nom         : " .. profile:getName())
print("Version     : " .. profile:getVersion())
print("Racine      : " .. profile:getRoot())
print("")

print("Configs chargées :")

if profile:getPackages() then
  print("- packages")
end

if profile:getServices() then
  print("- services")
end

if profile:getShell() then
  print("- shell")
end

if profile:getTheme() then
  print("- theme")
end

if profile:getAssets() then
  print("- assets")
end

print("")
print("RC0-11 OK : ProfileLoader retourne un objet Profile.")
