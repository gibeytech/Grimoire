package.path = "./?.lua;./?/init.lua;" .. package.path

local ServiceManager = require("installer.managers.service_manager")

print("== ServiceManager RC1-13 Test ==")

local plan = {
    services = {
        enabled = {
            "NetworkManager",
            "bluetooth",
            "sddm",
        },

        disabled = {
            "sshd",
        },
    },
}

print("")
print("[TEST] dry_run = true")

local dry_result = ServiceManager.enable(plan, {
    dry_run = true,
})

assert(dry_result.ok == true)
assert(dry_result.dry_run == true)
assert(dry_result.actions == 4)
assert(#dry_result.details.enabled == 3)
assert(#dry_result.details.disabled == 1)

print("")
print("[TEST] dry_run = false")

local real_result = ServiceManager.enable(plan, {
    dry_run = false,
})

assert(real_result.ok == true)
assert(real_result.dry_run == false)
assert(real_result.actions == 4)
assert(#real_result.details.enabled == 3)
assert(#real_result.details.disabled == 1)

print("")
print("RC1-13 OK : ServiceManager lit les services du profil.")
