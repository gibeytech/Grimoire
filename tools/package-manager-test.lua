package.path = "./?.lua;./?/init.lua;" .. package.path

local PackageManager = require("installer.managers.package_manager")

print("== PackageManager RC1-11 Test ==")

local plan = {
    packages = {
        groups = {
            base = {
                "git",
                "curl",
                "wget",
            },

            desktop = {
                "hyprland",
                "quickshell",
                "swaync",
                "git",
            },
        },
    },
}

print("")
print("[TEST] dry_run = true")

local dry_result = PackageManager.install(plan, {
    dry_run = true,
})

assert(dry_result.ok == true)
assert(dry_result.dry_run == true)
assert(dry_result.actions == 6)
assert(dry_result.command ~= nil)

print("")
print("[TEST] dry_run = false")

local real_result = PackageManager.install(plan, {
    dry_run = false,
})

assert(real_result.ok == true)
assert(real_result.dry_run == false)
assert(real_result.actions == 6)
assert(real_result.command ~= nil)

print("")
print("RC1-11 OK : PackageManager lit les groupes packages du profil.")
