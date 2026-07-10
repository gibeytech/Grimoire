package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local ServiceManager = require(
    "installer.managers.service_manager"
)

print("== ServiceManager RC4-A1 Test ==")

local plan = {
    services = {
        services = {
            {
                unit = "NetworkManager.service",
                operation = "enable",
                scope = "system",
            },
            {
                unit = "bluetooth.service",
                operation = "enable",
                scope = "system",
            },
            {
                unit = "wireplumber.service",
                operation = "enable",
                scope = "user",
            },
            {
                unit = "sshd.service",
                operation = "disable",
                scope = "system",
            },
        },
    },
}

print("")
print("[TEST] dry_run = true")

local dry_result =
    ServiceManager.enable(plan, {
        dry_run = true,
    })

assert(dry_result.ok == true)
assert(dry_result.dry_run == true)
assert(dry_result.actions == 4)
assert(#dry_result.details.enabled == 3)
assert(#dry_result.details.disabled == 1)
assert(#dry_result.details.definitions == 4)

assert(
    dry_result
        .details
        .definitions[3]
        .scope
        == "user"
)

print("")
print("[TEST] dry_run = false")

local safe_result =
    ServiceManager.enable(plan, {
        dry_run = false,
    })

assert(safe_result.ok == true)
assert(safe_result.dry_run == false)
assert(safe_result.actions == 4)
assert(#safe_result.details.enabled == 3)
assert(#safe_result.details.disabled == 1)

local legacy_result =
    ServiceManager.enable({
        services = {
            enabled = {
                "NetworkManager",
            },
            disabled = {
                "sshd",
            },
        },
    }, {
        dry_run = true,
    })

assert(legacy_result.ok == true)
assert(legacy_result.actions == 2)

assert(
    legacy_result
        .details
        .definitions[1]
        .scope
        == "system"
)

print("")
print(
    "RC4-A1 OK : ServiceManager lit le modèle "
        .. "explicite et conserve la compatibilité héritée."
)
