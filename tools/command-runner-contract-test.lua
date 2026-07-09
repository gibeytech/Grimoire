package.path = "./?.lua;./?/init.lua;" .. package.path

local CommandRunner = require("installer.command_runner")

print("== CommandRunner RC2-02 Contract Test ==")

local dry_run_result = CommandRunner.run("echo dry-run", {
    dry_run = true,
})

assert(dry_run_result.ok == true)
assert(dry_run_result.mode == "dry-run")
assert(dry_run_result.command == "echo dry-run")
assert(dry_run_result.prepared == true)
assert(dry_run_result.simulated == true)
assert(dry_run_result.executed == false)
assert(dry_run_result.exit_code == nil)
assert(dry_run_result.error == nil)

local apply_safe_result = CommandRunner.run("echo apply-safe", {
    dry_run = false,
})

assert(apply_safe_result.ok == true)
assert(apply_safe_result.mode == "apply-safe")
assert(apply_safe_result.command == "echo apply-safe")
assert(apply_safe_result.prepared == true)
assert(apply_safe_result.simulated == true)
assert(apply_safe_result.executed == false)
assert(apply_safe_result.exit_code == nil)
assert(apply_safe_result.error == nil)

local apply_real_result = CommandRunner.run("echo apply-real", {
    dry_run = false,
    apply_real = true,
})

assert(apply_real_result.ok == false)
assert(apply_real_result.mode == "apply-real")
assert(apply_real_result.command == "echo apply-real")
assert(apply_real_result.prepared == true)
assert(apply_real_result.simulated == false)
assert(apply_real_result.executed == false)
assert(apply_real_result.exit_code == nil)
assert(apply_real_result.error == "Mode apply-real non activé en RC2-01")

local invalid_result = CommandRunner.run("", {
    dry_run = true,
})

assert(invalid_result.ok == false)
assert(invalid_result.mode == "dry-run")
assert(invalid_result.command == "")
assert(invalid_result.prepared == false)
assert(invalid_result.simulated == false)
assert(invalid_result.executed == false)
assert(invalid_result.exit_code == nil)
assert(invalid_result.error == "Commande invalide")

print("")
print("RC2-02 OK : CommandRunner respecte le contrat prepare/simulate/execute/run.")
