package.path = "./?.lua;./?/init.lua;" .. package.path

local ServiceOperation = require("installer.service_operation")

print("== ServiceOperation RC2-06 Contract Test ==")

local action = {
    type = "service_operation",
    manager = "services",
    name = "enable-service",
    service = "NetworkManager",
    operation = "enable",
}

local dry_run_result = ServiceOperation.run(action, {
    dry_run = true,
})

assert(dry_run_result.ok == true)
assert(dry_run_result.mode == "dry-run")
assert(dry_run_result.service == "NetworkManager")
assert(dry_run_result.operation == "enable")
assert(dry_run_result.prepared == true)
assert(dry_run_result.simulated == true)
assert(dry_run_result.executed == false)
assert(dry_run_result.error == nil)

local apply_safe_result = ServiceOperation.run(action, {
    dry_run = false,
})

assert(apply_safe_result.ok == true)
assert(apply_safe_result.mode == "apply-safe")
assert(apply_safe_result.service == "NetworkManager")
assert(apply_safe_result.operation == "enable")
assert(apply_safe_result.prepared == true)
assert(apply_safe_result.simulated == true)
assert(apply_safe_result.executed == false)
assert(apply_safe_result.error == nil)

local apply_real_result = ServiceOperation.run(action, {
    dry_run = false,
    apply_real = true,
})

assert(apply_real_result.ok == false)
assert(apply_real_result.mode == "apply-real")
assert(apply_real_result.service == "NetworkManager")
assert(apply_real_result.operation == "enable")
assert(apply_real_result.prepared == true)
assert(apply_real_result.simulated == false)
assert(apply_real_result.executed == false)
assert(apply_real_result.error == "Mode apply-real non activé en RC2-05")

local invalid_result = ServiceOperation.run({}, {
    dry_run = true,
})

assert(invalid_result.ok == false)
assert(invalid_result.mode == "dry-run")
assert(invalid_result.prepared == false)
assert(invalid_result.simulated == false)
assert(invalid_result.executed == false)
assert(invalid_result.error == "Opération service invalide")

print("")
print("RC2-06 OK : ServiceOperation respecte le contrat prepare/simulate/execute/run.")
