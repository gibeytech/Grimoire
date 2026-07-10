package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local ServiceOperation = require(
    "installer.service_operation"
)

print(
    "== ServiceOperation RC4-A1 Contract Test =="
)

local action = {
    type = "service_operation",
    manager = "services",
    name = "enable-service",
    service = "NetworkManager.service",
    unit = "NetworkManager.service",
    operation = "enable",
    scope = "system",
}

local dry_run_result =
    ServiceOperation.run(action, {
        dry_run = true,
    })

assert(dry_run_result.ok == true)
assert(dry_run_result.mode == "dry-run")

assert(
    dry_run_result.service
        == "NetworkManager.service"
)

assert(
    dry_run_result.unit
        == "NetworkManager.service"
)

assert(dry_run_result.operation == "enable")
assert(dry_run_result.scope == "system")
assert(dry_run_result.prepared == true)
assert(dry_run_result.simulated == true)
assert(dry_run_result.executed == false)
assert(dry_run_result.error == nil)

local apply_safe_result =
    ServiceOperation.run(action, {
        dry_run = false,
    })

assert(apply_safe_result.ok == true)
assert(apply_safe_result.mode == "apply-safe")
assert(apply_safe_result.scope == "system")
assert(apply_safe_result.prepared == true)
assert(apply_safe_result.simulated == true)
assert(apply_safe_result.executed == false)
assert(apply_safe_result.error == nil)

local apply_real_result =
    ServiceOperation.run(action, {
        dry_run = false,
        apply_real = true,
    })

assert(apply_real_result.ok == false)
assert(apply_real_result.mode == "apply-real")
assert(apply_real_result.scope == "system")
assert(apply_real_result.prepared == true)
assert(apply_real_result.simulated == false)
assert(apply_real_result.executed == false)

assert(
    apply_real_result.error
        == "Mode apply-real non activé pendant RC4-A1"
)

local legacy_action_result =
    ServiceOperation.run({
        service = "bluetooth",
        operation = "enable",
    }, {
        dry_run = true,
    })

assert(legacy_action_result.ok == true)
assert(legacy_action_result.scope == "system")
assert(legacy_action_result.service == "bluetooth")

local invalid_scope_result =
    ServiceOperation.run({
        service = "invalid.service",
        operation = "enable",
        scope = "session",
    }, {
        dry_run = true,
    })

assert(invalid_scope_result.ok == false)
assert(invalid_scope_result.prepared == false)
assert(invalid_scope_result.executed == false)

assert(
    invalid_scope_result.error
        == "Scope service inconnu : session"
)

local invalid_operation_result =
    ServiceOperation.run({
        service = "invalid.service",
        operation = "restart",
        scope = "system",
    }, {
        dry_run = true,
    })

assert(invalid_operation_result.ok == false)
assert(invalid_operation_result.prepared == false)

assert(
    invalid_operation_result.error
        == "Opération service inconnue : restart"
)

local invalid_result =
    ServiceOperation.run({}, {
        dry_run = true,
    })

assert(invalid_result.ok == false)
assert(invalid_result.mode == "dry-run")
assert(invalid_result.prepared == false)
assert(invalid_result.simulated == false)
assert(invalid_result.executed == false)
assert(invalid_result.error == "Unité systemd manquante")

print("")
print(
    "RC4-A1 OK : ServiceOperation transporte "
        .. "l’unité, l’opération et le scope."
)
