package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local ServiceOperation = require(
    "installer.service_operation"
)

print(
    "== ServiceOperation RC4-A2 Contract Test =="
)

local function shell_quote(value)
    return "'"
        .. tostring(value):gsub(
            "'",
            "'\\''"
        )
        .. "'"
end

local function command_succeeded(command)
    local ok, _, code = os.execute(command)

    return ok == true
        or ok == 0
        or code == 0
end

local function write_file(path, content)
    local file = assert(io.open(path, "wb"))

    assert(file:write(content))
    assert(file:close())
end

local function read_state(path)
    local file = assert(io.open(path, "rb"))
    local content = assert(file:read("*a"))

    assert(file:close())

    return content:match("^%s*(.-)%s*$")
end

local temporary_directory = os.tmpname()

os.remove(temporary_directory)

assert(command_succeeded(
    "mkdir -p -- "
        .. shell_quote(temporary_directory)
))

local state_path =
    temporary_directory .. "/state"

local fake_systemctl =
    temporary_directory .. "/systemctl"

write_file(state_path, "disabled\n")

write_file(
    fake_systemctl,
    table.concat({
        "#!/bin/sh",
        "set -eu",
        "state_file=" .. shell_quote(state_path),
        "",
        "if [ \"${1-}\" = \"--user\" ]; then",
        "    shift",
        "fi",
        "",
        "command=\"${1-}\"",
        "shift",
        "",
        "case \"$command\" in",
        "    show)",
        "        state=\"$(cat \"$state_file\")\"",
        "        printf '%s\\n' \\",
        "            'LoadState=loaded' \\",
        "            \"UnitFileState=$state\"",
        "        ;;",
        "    enable)",
        "        printf '%s\\n' enabled > \"$state_file\"",
        "        ;;",
        "    disable)",
        "        printf '%s\\n' disabled > \"$state_file\"",
        "        ;;",
        "    *)",
        "        exit 64",
        "        ;;",
        "esac",
        "",
    }, "\n")
)

assert(command_succeeded(
    "chmod 700 -- "
        .. shell_quote(fake_systemctl)
))

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
assert(dry_run_result.prepared == true)
assert(dry_run_result.simulated == true)
assert(dry_run_result.inspected == false)
assert(dry_run_result.executed == false)
assert(dry_run_result.command:find("sudo", 1, true))
assert(dry_run_result.error == nil)

local apply_safe_result =
    ServiceOperation.run(action, {
        dry_run = false,
    })

assert(apply_safe_result.ok == true)
assert(apply_safe_result.mode == "apply-safe")
assert(apply_safe_result.simulated == true)
assert(apply_safe_result.executed == false)
assert(apply_safe_result.error == nil)

local apply_real_result =
    ServiceOperation.run(action, {
        dry_run = false,
        apply_real = true,
        systemctl_path = fake_systemctl,
        elevate_system = false,
    })

assert(apply_real_result.ok == true)
assert(apply_real_result.mode == "apply-real")
assert(apply_real_result.prepared == true)
assert(apply_real_result.simulated == false)
assert(apply_real_result.inspected == true)
assert(apply_real_result.executed == true)
assert(apply_real_result.changed == true)
assert(apply_real_result.already_satisfied == false)
assert(apply_real_result.state_before.unit_file_state == "disabled")
assert(apply_real_result.state_after.unit_file_state == "enabled")
assert(apply_real_result.error == nil)
assert(read_state(state_path) == "enabled")

local idempotent_result =
    ServiceOperation.run(action, {
        dry_run = false,
        apply_real = true,
        systemctl_path = fake_systemctl,
        elevate_system = false,
    })

assert(idempotent_result.ok == true)
assert(idempotent_result.executed == false)
assert(idempotent_result.changed == false)
assert(idempotent_result.already_satisfied == true)
assert(idempotent_result.reason == "already-satisfied")

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

assert(
    invalid_scope_result.error
        == "Scope service inconnu : session"
)

local invalid_result =
    ServiceOperation.run({}, {
        dry_run = true,
    })

assert(invalid_result.ok == false)
assert(invalid_result.prepared == false)
assert(invalid_result.executed == false)
assert(invalid_result.error == "Unité systemd manquante")

assert(command_succeeded(
    "rm -rf -- "
        .. shell_quote(
            temporary_directory
        )
))

print("")
print(
    "RC4-A2 OK : ServiceOperation active "
        .. "l’apply-real idempotent via ServiceExecutor."
)
