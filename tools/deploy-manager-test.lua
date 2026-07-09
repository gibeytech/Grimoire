package.path = "./?.lua;./?/init.lua;" .. package.path

local DeployManager = require("installer.managers.deploy_manager")

print("== DeployManager RC1-16 Test ==")

local plan = {
    profile = {
        root = "profiles/gibeytech",
    },

    dotfiles = {
        source = "dotfiles",
    },
}

print("")
print("[TEST] dry_run = true")

local dry_result = DeployManager.deploy(plan, {
    dry_run = true,
})

assert(dry_result.ok == true)
assert(dry_result.dry_run == true)
assert(dry_result.actions == 1)
assert(#dry_result.details.deployments == 1)
assert(dry_result.details.deployments[1].source == "profiles/gibeytech/dotfiles")
assert(dry_result.details.deployments[1].destination == "~/.config")

print("")
print("[TEST] dry_run = false")

local real_result = DeployManager.deploy(plan, {
    dry_run = false,
})

assert(real_result.ok == true)
assert(real_result.dry_run == false)
assert(real_result.actions == 1)
assert(#real_result.details.deployments == 1)

print("")
print("RC1-16 OK : DeployManager lit les dotfiles du profil.")
