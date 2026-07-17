package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local ServiceExecutor = require(
    "installer.service_executor"
)

print(
    "== ServiceExecutor RC4-A2 Contract Test =="
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

local function read_file(path)
    local file = assert(io.open(path, "rb"))
    local content = assert(file:read("*a"))

    assert(file:close())

    return content
end

local function write_state(path, state)
    write_file(path, tostring(state) .. "\n")
end

local function read_state(path)
    return read_file(path):match("^%s*(.-)%s*$")
end

local function read_lines(path)
    local lines = {}

    for line in read_file(path):gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    return lines
end

local temporary_directory = os.tmpname()

os.remove(temporary_directory)

assert(command_succeeded(
    "mkdir -p -- "
        .. shell_quote(temporary_directory)
))

local state_path =
    temporary_directory .. "/state"

local log_path =
    temporary_directory .. "/calls.log"

local fake_systemctl =
    temporary_directory .. "/systemctl"

write_state(state_path, "disabled")
write_file(log_path, "")

write_file(
    fake_systemctl,
    table.concat({
        "#!/bin/sh",
        "set -eu",
        "state_file=" .. shell_quote(state_path),
        "log_file=" .. shell_quote(log_path),
        "scope=system",
        "",
        "if [ \"${1-}\" = \"--user\" ]; then",
        "    scope=user",
        "    shift",
        "fi",
        "",
        "command=\"${1-}\"",
        "shift",
        "",
        "printf '%s|%s|%s\\n' \\",
        "    \"$scope\" \"$command\" \"$*\" \\",
        "    >> \"$log_file\"",
        "",
        "case \"$command\" in",
        "    show)",
        "        state=\"$(cat \"$state_file\")\"",
        "",
        "        if [ \"$state\" = \"not-found\" ]; then",
        "            printf '%s\\n' \\",
        "                'LoadState=not-found' \\",
        "                'UnitFileState='",
        "        else",
        "            printf '%s\\n' \\",
        "                'LoadState=loaded' \\",
        "                \"UnitFileState=$state\"",
        "        fi",
        "        ;;",
        "",
        "    enable)",
        "        if [ \"$(cat \"$state_file\")\" = \"fail-enable\" ]; then",
        "            printf '%s\\n' 'enable failure' >&2",
        "            exit 5",
        "        fi",
        "",
        "        printf '%s\\n' enabled > \"$state_file\"",
        "        ;;",
        "",
        "    disable)",
        "        printf '%s\\n' disabled > \"$state_file\"",
        "        ;;",
        "",
        "    *)",
        "        printf '%s\\n' \"unknown command: $command\" >&2",
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

local common_options = {
    systemctl_path = fake_systemctl,
    elevate_system = false,
}

local prepared =
    ServiceExecutor.prepare({
        unit = "demo.service",
        operation = "enable",
        scope = "system",
    }, common_options)

assert(prepared.ok == true)
assert(prepared.prepared == true)
assert(prepared.elevated == false)
assert(prepared.command:find("enable", 1, true))
assert(prepared.inspect_command:find("show", 1, true))

local enabled =
    ServiceExecutor.execute({
        unit = "demo.service",
        operation = "enable",
        scope = "system",
    }, common_options)

assert(enabled.ok == true)
assert(enabled.inspected == true)
assert(enabled.executed == true)
assert(enabled.changed == true)
assert(enabled.already_satisfied == false)
assert(enabled.state_before.load_state == "loaded")
assert(enabled.state_before.unit_file_state == "disabled")
assert(enabled.state_after.unit_file_state == "enabled")
assert(enabled.exit_code == 0)
assert(enabled.error == nil)
assert(read_state(state_path) == "enabled")

local calls = read_lines(log_path)

assert(#calls == 3)
assert(calls[1]:find("system|show|", 1, true) == 1)
assert(calls[2]:find("system|enable|", 1, true) == 1)
assert(calls[3]:find("system|show|", 1, true) == 1)

local already_enabled =
    ServiceExecutor.execute({
        unit = "demo.service",
        operation = "enable",
        scope = "system",
    }, common_options)

assert(already_enabled.ok == true)
assert(already_enabled.inspected == true)
assert(already_enabled.executed == false)
assert(already_enabled.changed == false)
assert(already_enabled.already_satisfied == true)
assert(already_enabled.reason == "already-satisfied")
assert(already_enabled.state_after.unit_file_state == "enabled")

calls = read_lines(log_path)

assert(#calls == 4)
assert(calls[4]:find("system|show|", 1, true) == 1)

write_state(state_path, "enabled")

local user_disabled =
    ServiceExecutor.execute({
        unit = "demo-user.service",
        operation = "disable",
        scope = "user",
    }, common_options)

assert(user_disabled.ok == true)
assert(user_disabled.executed == true)
assert(user_disabled.changed == true)
assert(user_disabled.scope == "user")
assert(user_disabled.state_before.unit_file_state == "enabled")
assert(user_disabled.state_after.unit_file_state == "disabled")

calls = read_lines(log_path)

assert(#calls == 7)
assert(calls[5]:find("user|show|", 1, true) == 1)
assert(calls[6]:find("user|disable|", 1, true) == 1)
assert(calls[7]:find("user|show|", 1, true) == 1)

write_state(state_path, "static")

local static_disabled =
    ServiceExecutor.execute({
        unit = "static.service",
        operation = "disable",
        scope = "system",
    }, common_options)

assert(static_disabled.ok == true)
assert(static_disabled.executed == false)
assert(static_disabled.changed == false)
assert(static_disabled.already_satisfied == true)
assert(static_disabled.state_after.unit_file_state == "static")

write_state(state_path, "not-found")

local missing =
    ServiceExecutor.execute({
        unit = "missing.service",
        operation = "enable",
        scope = "system",
    }, common_options)

assert(missing.ok == false)
assert(missing.executed == false)
assert(missing.changed == false)
assert(missing.reason == "unit-not-loaded")

assert(
    missing.error:find(
        "Unité systemd indisponible",
        1,
        true
    ) ~= nil
)

write_state(state_path, "fail-enable")

local failed =
    ServiceExecutor.execute({
        unit = "failing.service",
        operation = "enable",
        scope = "system",
    }, common_options)

assert(failed.ok == false)
assert(failed.executed == true)
assert(failed.changed == false)
assert(failed.exit_code == 5)
assert(failed.system.stderr:find(
    "enable failure",
    1,
    true
) ~= nil)

local elevated =
    ServiceExecutor.prepare({
        unit = "system.service",
        operation = "enable",
        scope = "system",
    }, {
        systemctl_path = fake_systemctl,
        sudo_path = "/usr/bin/sudo",
    })

assert(elevated.ok == true)
assert(elevated.elevated == true)

assert(
    elevated.command:find(
        "/usr/bin/sudo",
        1,
        true
    ) ~= nil
)

local cleanup_ok =
    command_succeeded(
        "rm -rf -- "
            .. shell_quote(
                temporary_directory
            )
    )

assert(cleanup_ok == true)

print("")
print(
    "RC4-A2 OK : ServiceExecutor inspecte, "
        .. "converge et vérifie les unités systemd "
        .. "sans répéter les mutations déjà satisfaites."
)
