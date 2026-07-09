package.path = "./?.lua;./?/init.lua;" .. package.path

local PackageManager = require("installer.managers.package_manager")

print("== PackageManager RC1-12 Test ==")

local plan = {
    packages = {
        groups = {
            desktop = {
                "hyprland",
                "quickshell",
                "swaync",
                "git",
            },

            base = {
                "git",
                "curl",
                "wget",
            },

            custom = {
                "zellij",
            },
        },
    },
}

local expected_command = "sudo pacman -S --needed git curl wget hyprland quickshell swaync zellij"

print("")
print("[TEST] dry_run = true")

local dry_result = PackageManager.install(plan, {
    dry_run = true,
})

assert(dry_result.ok == true)
assert(dry_result.dry_run == true)
assert(dry_result.actions == 7)
assert(dry_result.command == expected_command)

print("")
print("[TEST] dry_run = false")

local real_result = PackageManager.install(plan, {
    dry_run = false,
})

assert(real_result.ok == true)
assert(real_result.dry_run == false)
assert(real_result.actions == 7)
assert(real_result.command == expected_command)

print("")
print("RC1-12 OK : PackageManager respecte un ordre déterministe.")
