package.path = "./?.lua;./?/init.lua;" .. package.path

local CommandRunner = require("installer.command_runner")

print("== CommandRunner RC2-B2 Contract Test ==")

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

local apply_real_success = CommandRunner.run("true", {
    dry_run = false,
    apply_real = true,
})

assert(apply_real_success.ok == true)
assert(apply_real_success.mode == "apply-real")
assert(apply_real_success.command == "true")
assert(apply_real_success.prepared == true)
assert(apply_real_success.simulated == false)
assert(apply_real_success.executed == true)
assert(apply_real_success.exit_code == 0)
assert(type(apply_real_success.system) == "table")
assert(apply_real_success.error == nil)

local apply_real_failure = CommandRunner.run("false", {
    dry_run = false,
    apply_real = true,
})

assert(apply_real_failure.ok == false)
assert(apply_real_failure.mode == "apply-real")
assert(apply_real_failure.command == "false")
assert(apply_real_failure.prepared == true)
assert(apply_real_failure.simulated == false)
assert(apply_real_failure.executed == true)
assert(apply_real_failure.exit_code ~= 0)
assert(type(apply_real_failure.system) == "table")
assert(apply_real_failure.error == "Commande système échouée")

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
print("RC2-B2 OK : CommandRunner exécute apply-real via SystemExecutor.")
