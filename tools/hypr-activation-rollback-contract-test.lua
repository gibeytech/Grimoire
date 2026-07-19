package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local HyprActivationOperation = require(
    "installer.hypr_activation_operation"
)

local HyprActivationRollback = require(
    "installer.hypr_activation_rollback"
)

print(
    "== HyprActivationRollback "
        .. "RC4-D10A1 Contract Test =="
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
        "hl.config({",
        "    input = {",
        "        kb_layout = \"fr\",",
        "    },",
        "})",
        "",
    }, "\n")

write_file(target, original)
write_file(loader, "return true\n")

local activation =
    HyprActivationOperation.run(
        {
            destination = target,
            loader = loader,
            backup = backup,
            line =
                'require("grimoire-loader")',
        },
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(activation.ok == true)
assert(activation.status == "activated")
assert(read_file(target) ~= original)

local metadata =
    activation.compensation

local dry_run =
    HyprActivationRollback.run(
        metadata,
        {
            dry_run = true,
        }
    )

assert(dry_run.ok == true)
assert(dry_run.status == "simulated")
assert(dry_run.executed == false)
assert(read_file(target) ~= original)

local rollback =
    HyprActivationRollback.run(
        metadata,
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(rollback.ok == true)
assert(rollback.status == "restored")
assert(rollback.executed == true)
assert(rollback.restored == true)
assert(rollback.removed_backup == true)
assert(read_file(target) == original)

assert(
    not command_succeeded(
        "test -e " .. shell_quote(backup)
    )
)

local repeated =
    HyprActivationRollback.run(
        metadata,
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(repeated.ok == true)

assert(
    repeated.status
        == "already-restored"
)

assert(repeated.executed == false)
assert(repeated.already_restored == true)
assert(read_file(target) == original)

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
    "RC4-D10A1 OK : la sauvegarde restaure "
        .. "exactement le fichier original."
)
