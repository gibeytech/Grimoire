package.path = "./?.lua;./?/init.lua;" .. package.path

local ProfileLoader = require("core.loader.profile_loader")

local profile_id = arg[1] or "gibeytech"
local profile = ProfileLoader.load(profile_id)

print("== Grimoire V3 — Profile Inspect ==")
print("ID          : " .. profile.id)
print("Nom         : " .. profile.name)
print("Version     : " .. profile.version)
print("Racine      : " .. profile.root)
print("")

print("Configs chargées :")
print("- packages")
print("- services")
print("- shell")
print("- theme")
print("- assets")
print("")

print("RC0-09 OK : profil Lua chargé avec succès.")
