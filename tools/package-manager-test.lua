package.path = "./?.lua;./?/init.lua;" .. package.path

local PackageManager = require("installer.managers.package_manager")

print("== PackageManager RC1-07 Test ==")

local plan = {
    packages = {
        groups = {
            {
                name = "base",
                packages = {
                    "git",
                    "curl",
                    "wget",
                },
            },
            {
                name = "desktop",
                packages = {
                    "hyprland",
                    "quickshell",
                    "swaync",
                    "git",
                },
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
assert(dry_result.command == "sudo pacman -S --needed git curl wget hyprland quickshell swaync")

print("")
print("[TEST] dry_run = false")

local real_result = PackageManager.install(plan, {
    dry_run = false,
})

assert(real_result.ok == true)
assert(real_result.dry_run == false)
assert(real_result.command == "sudo pacman -S --needed git curl wget hyprland quickshell swaync")

print("")
print("RC1-07 OK : PackageManager expose une API install(plan, options).")
