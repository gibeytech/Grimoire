package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local HyprActivationOperation = require(
    "installer.hypr_activation_operation"
)

print(
    "== HyprActivation "
        .. "RC4-D10A1 Apply-Real Test =="
)

local line =
    'require("grimoire-loader")'

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
    local content = file:read("*a")
    file:close()
    return content
end

local temporary_directory =
    os.tmpname()

os.remove(temporary_directory)

assert(
    command_succeeded(
        "mkdir -p -- "
            .. shell_quote(
                temporary_directory
            )
    )
)

local target =
    temporary_directory
        .. "/hyprland.lua"

local loader =
    temporary_directory
        .. "/grimoire-loader.lua"

local backup =
    temporary_directory
        .. "/state/hyprland.lua.bak"

local original =
    table.concat({
        "local mainMod = \"SUPER\"",
        "hl.config({",
        "    input = { kb_layout = \"fr\" },",
        "})",
        "",
    }, "\n")

write_file(target, original)
write_file(loader, "return true\n")

local action = {
    destination = target,
    loader = loader,
    backup = backup,
    line = line,
}

local first =
    HyprActivationOperation.run(
        action,
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(first.ok == true)
assert(first.mode == "apply-real")
assert(first.status == "activated")
assert(first.executed == true)
assert(first.changed == true)
assert(first.already_satisfied == false)
assert(first.skipped == false)

assert(type(first.compensation) == "table")

assert(
    first.compensation.status == "ready"
)

assert(
    first.compensation.reversible == true
)

assert(
    first.compensation.compensation_type
        == "restore-backup"
)

assert(
    command_succeeded(
        "test -f " .. shell_quote(backup)
    )
)

local activated = read_file(target)

assert(
    activated:find(
        line,
        1,
        true
    ) ~= nil
)

local count_process = assert(
    io.popen(
        "grep -Fxc -- "
            .. shell_quote(line)
            .. " "
            .. shell_quote(target),
        "r"
    )
)

local line_count =
    tonumber(count_process:read("*l"))

count_process:close()

assert(line_count == 1)
assert(command_succeeded("luac -p " .. shell_quote(target)))

local second =
    HyprActivationOperation.run(
        action,
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(second.ok == true)

assert(
    second.status
        == "already-satisfied"
)

assert(second.executed == false)
assert(second.changed == false)
assert(second.already_satisfied == true)
assert(second.skipped == true)
assert(second.compensation == nil)

assert(read_file(target) == activated)

assert(
    command_succeeded(
        "rm -rf -- "
            .. shell_quote(
                temporary_directory
            )
    )
)

print("")
print(
    "RC4-D10A1 OK : l’activation est "
        .. "atomique et idempotente."
)
