package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local ExecutionPlan = require(
    "installer.model.execution_plan"
)

local Executor = require(
    "installer.executor"
)

print(
    "== Service RC4-A2 Apply-Real Integration Test =="
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

local plan = ExecutionPlan:new({
    profile = {
        id = "rc4-a2-service",
        name = "RC4-A2 Service",
    },
    mode = "apply-real",
    actions = {
        {
            type = "service_operation",
            manager = "services",
            name = "enable-service",
            unit = "demo.service",
            service = "demo.service",
            operation = "enable",
            scope = "system",
        },
    },
})

local options = {
    dry_run = false,
    apply_real = true,
    systemctl_path = fake_systemctl,
    elevate_system = false,
}

local first_execution =
    Executor.execute(plan, options)

assert(first_execution.ok == true)
assert(first_execution.mode == "apply-real")
assert(first_execution.transaction_status == "committed")
assert(first_execution.executed_actions == 1)
assert(#first_execution.results == 1)
assert(#first_execution.journal == 1)

local first_service =
    first_execution
        .results[1]
        .details
        .service

assert(first_service.ok == true)
assert(first_service.executed == true)
assert(first_service.changed == true)
assert(first_service.already_satisfied == false)
assert(first_service.state_before.unit_file_state == "disabled")
assert(first_service.state_after.unit_file_state == "enabled")

local first_entry =
    first_execution.journal[1]

assert(first_entry.ok == true)
assert(first_entry.type == "service_operation")
assert(first_entry.manager == "services")
assert(first_entry.mode == "apply-real")
assert(first_entry.prepared == true)
assert(first_entry.simulated == false)
assert(first_entry.executed == true)
assert(first_entry.exit_code == 0)
assert(first_entry.reason == "exit")
assert(first_entry.command:find("enable", 1, true))
assert(first_entry.error == nil)

local second_execution =
    Executor.execute(plan, options)

assert(second_execution.ok == true)
assert(second_execution.transaction_status == "committed")
assert(second_execution.executed_actions == 0)
assert(#second_execution.journal == 1)

local second_service =
    second_execution
        .results[1]
        .details
        .service

assert(second_service.ok == true)
assert(second_service.executed == false)
assert(second_service.changed == false)
assert(second_service.already_satisfied == true)
assert(second_service.reason == "already-satisfied")

local second_entry =
    second_execution.journal[1]

assert(second_entry.ok == true)
assert(second_entry.executed == false)
assert(second_entry.exit_code == 0)
assert(second_entry.reason == "already-satisfied")
assert(second_entry.error == nil)

assert(command_succeeded(
    "rm -rf -- "
        .. shell_quote(
            temporary_directory
        )
))

print("")
print(
    "RC4-A2 OK : Executor exécute et journalise "
        .. "les services systemd réels de manière idempotente."
)
