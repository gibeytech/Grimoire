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
            destination = "~/.local/share/themes",
        },

        icons = {
            source = "icons",
            destination = "~/.local/share/icons",
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
assert(#dry_result.details.operations == 3)

for _, operation in ipairs(dry_result.details.operations) do
    assert(operation.ok == true)
    assert(operation.mode == "dry-run")
    assert(operation.prepared == true)
    assert(operation.simulated == true)
    assert(operation.executed == false)
    assert(type(operation.command) == "string")
    assert(operation.command ~= "")
    assert(operation.system_result == nil)
    assert(operation.error == nil)
end

print("")
print("[TEST] dry_run = false")

local apply_safe_result = AssetManager.deploy(plan, {
    dry_run = false,
})

assert(apply_safe_result.ok == true)
assert(apply_safe_result.dry_run == false)
assert(apply_safe_result.actions == 3)
assert(#apply_safe_result.details.assets == 3)
assert(#apply_safe_result.details.operations == 3)

for _, operation in ipairs(apply_safe_result.details.operations) do
    assert(operation.ok == true)
    assert(operation.mode == "apply-safe")
    assert(operation.prepared == true)
    assert(operation.simulated == true)
    assert(operation.executed == false)
    assert(type(operation.command) == "string")
    assert(operation.command ~= "")
    assert(operation.system_result == nil)
    assert(operation.error == nil)
end

print("")
print("RC1-15 OK : AssetManager prépare les assets en dry-run et apply-safe.")
