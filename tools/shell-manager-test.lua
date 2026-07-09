package.path = "./?.lua;./?/init.lua;" .. package.path

local ShellManager = require("installer.managers.shell_manager")

print("== ShellManager RC1-14 Test ==")

local plan = {
    shell = {
        runtime = "grimoire-shell",

        modules = {
            "bar",
            "hub",
            "launcher",
        },
    },
}

print("")
print("[TEST] dry_run = true")

local dry_result = ShellManager.deploy(plan, {
    dry_run = true,
})

assert(dry_result.ok == true)
assert(dry_result.dry_run == true)
assert(dry_result.actions == 3)
assert(dry_result.details.runtime == "grimoire-shell")
assert(#dry_result.details.modules == 3)

print("")
print("[TEST] dry_run = false")

local real_result = ShellManager.deploy(plan, {
    dry_run = false,
})

assert(real_result.ok == true)
assert(real_result.dry_run == false)
assert(real_result.actions == 3)
assert(real_result.details.runtime == "grimoire-shell")
assert(#real_result.details.modules == 3)

print("")
print("RC1-14 OK : ShellManager lit la configuration Grimoire Shell.")
