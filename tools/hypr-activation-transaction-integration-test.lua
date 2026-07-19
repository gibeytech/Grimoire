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
    "== HyprActivation RC4-D10A2 "
        .. "Transaction Integration Test =="
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

local function path_exists(path)
    return command_succeeded(
        "test -e "
            .. shell_quote(path)
            .. " || test -L "
            .. shell_quote(path)
    )
end

local function write_file(path, content)
    local file = assert(
        io.open(path, "wb")
    )

    assert(file:write(content))
    assert(file:close())
end

local function read_file(path)
    local file = assert(
        io.open(path, "rb")
    )

    local content = file:read("*a")
    file:close()

    return content
end

local temporary_directory =
    os.tmpname()

os.remove(temporary_directory)

assert(
    temporary_directory:match("^/tmp/")
)

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
        "    input = {",
        "        kb_layout = \"fr\",",
        "    },",
        "})",
        "",
    }, "\n")

write_file(target, original)
write_file(loader, "return true\n")

local activation_action = {
    type = "hypr_activation",
    manager = "deploy",
    name = "activate-hypr",
    destination = target,
    loader = loader,
    backup = backup,
    line = line,
}

local rollback_plan =
    ExecutionPlan:new({
        profile = {
            id = "hypr-rollback",
            name = "Hypr Rollback",
        },
        mode = "apply-real",
        actions = {
            activation_action,
            {
                type = "command",
                manager = "packages",
                name = "forced-failure",
                command = "false",
            },
        },
    })

local rollback_execution =
    Executor.execute(
        rollback_plan,
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(rollback_execution.ok == false)

assert(
    rollback_execution.transaction_status
        == "rolled-back"
)

assert(rollback_execution.failed_at == "packages")
assert(#rollback_execution.journal == 2)

assert(
    rollback_execution.journal[1].type
        == "hypr_activation"
)

assert(
    rollback_execution.journal[1]
        .executed == true
)

assert(
    rollback_execution.journal[1]
        .compensation
        .kind == "hypr_activation"
)

assert(
    rollback_execution.rollback.attempted
        == true
)

assert(
    rollback_execution.rollback
        .successful_actions == 1
)

assert(read_file(target) == original)
assert(path_exists(backup) == false)

local commit_plan =
    ExecutionPlan:new({
        profile = {
            id = "hypr-commit",
            name = "Hypr Commit",
        },
        mode = "apply-real",
        actions = {
            activation_action,
        },
    })

local committed_execution =
    Executor.execute(
        commit_plan,
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(committed_execution.ok == true)

assert(
    committed_execution.transaction_status
        == "committed"
)

assert(
    type(committed_execution.commit)
        == "table"
)

assert(
    committed_execution.commit.status
        == "committed"
)

assert(
    committed_execution.commit.attempted
        == true
)

assert(
    committed_execution.commit
        .total_actions == 1
)

assert(
    committed_execution.commit
        .successful_actions == 1
)

assert(
    committed_execution.commit
        .executed_actions == 1
)

assert(
    committed_execution.commit
        .results[1]
        .status == "cleaned"
)

assert(path_exists(backup) == false)

local activated = read_file(target)

assert(
    activated:find(
        line,
        1,
        true
    ) ~= nil
)

assert(
    command_succeeded(
        "luac -p "
            .. shell_quote(target)
    )
)

local second_execution =
    Executor.execute(
        commit_plan,
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(second_execution.ok == true)

assert(
    second_execution.transaction_status
        == "committed"
)

assert(
    second_execution.results[1]
        .details
        .hypr_activation
        .status
        == "already-satisfied"
)

assert(
    second_execution.results[1]
        .details
        .hypr_activation
        .executed == false
)

assert(
    second_execution.results[1]
        .details
        .hypr_activation
        .compensation == nil
)

assert(
    second_execution.commit.status
        == "committed"
)

assert(
    second_execution.commit.attempted
        == false
)

assert(read_file(target) == activated)
assert(path_exists(backup) == false)

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
    "RC4-D10A2 OK : le pipeline restaure "
        .. "après échec, nettoie après commit "
        .. "et reste idempotent."
)
