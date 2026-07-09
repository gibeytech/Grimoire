package.path = "./?.lua;./?/init.lua;" .. package.path

local AssetManager = require("installer.managers.asset_manager")

print("== AssetManager RC1-15 Test ==")

local plan = {
    assets = {
        wallpapers = {
            source = "wallpapers",
            destination = "~/.local/share/grimoire/wallpapers",
        },

        themes = {
            source = "themes",
        },

        icons = {
            source = "icons",
        },
    },
}

print("")
print("[TEST] dry_run = true")

local dry_result = AssetManager.deploy(plan, {
    dry_run = true,
})

assert(dry_result.ok == true)
assert(dry_result.dry_run == true)
assert(dry_result.actions == 3)
assert(#dry_result.details.assets == 3)
assert(dry_result.details.assets[1].name == "icons")
assert(dry_result.details.assets[2].name == "themes")
assert(dry_result.details.assets[3].name == "wallpapers")

print("")
print("[TEST] dry_run = false")

local real_result = AssetManager.deploy(plan, {
    dry_run = false,
})

assert(real_result.ok == true)
assert(real_result.dry_run == false)
assert(real_result.actions == 3)
assert(#real_result.details.assets == 3)

print("")
print("RC1-15 OK : AssetManager lit les assets du profil.")
