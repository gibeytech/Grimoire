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
    "== Executor RC4-D8 "
        .. "Filesystem Preflight Test =="
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

local source =
    temporary_directory .. "/source"

local conflict_destination =
    temporary_directory .. "/conflict"

local ready_destination =
    temporary_directory .. "/ready"

local command_marker =
    temporary_directory .. "/command-ran"

assert(
    command_succeeded(
        "mkdir -p -- "
            .. shell_quote(source)
            .. " "
            .. shell_quote(
                conflict_destination
            )
    )
)

write_file(
    source .. "/content.txt",
    "source\n"
)

write_file(
    conflict_destination .. "/content.txt",
    "destination divergente\n"
)

local plan =
    ExecutionPlan:new({
        profile = {
            id = "rc4-d8-executor",
            name = "RC4-D8 Executor",
        },

        mode = "apply-real",

        actions = {
            {
                type = "command",
                manager = "packages",
                name = "must-not-run",
                command =
                    "touch -- "
                        .. shell_quote(
                            command_marker
                        ),
            },

            {
                type = "file_operation",
                manager = "assets",
                name = "ready-copy",
                operation = {
                    type = "copy",
                    source = source,
                    destination =
                        ready_destination,
                    overwrite = false,
                },
            },

            {
                type = "file_operation",
                manager = "deploy",
                name = "late-conflict",
                operation = {
                    type = "copy",
                    source = source,
                    destination =
                        conflict_destination,
                    overwrite = false,
                },
            },
        },
    })

local result =
    Executor.execute(
        plan,
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(result.ok == false)
assert(result.mode == "apply-real")

assert(
    result.transaction_status
        == "preflight-failed"
)

assert(result.failure_kind == "preflight")

assert(
    result.failed_at
        == "filesystem-preflight"
)

assert(result.executed_actions == 0)
assert(#result.results == 0)
assert(#result.journal == 0)

assert(
    result.rollback.attempted == false
)

assert(
    result.rollback.status
        == "not-required"
)

assert(
    type(result.filesystem_preflight)
        == "table"
)

assert(
    result.filesystem_preflight.status
        == "blocked"
)

assert(
    result.filesystem_preflight
        .counts
        .ready_create == 1
)

assert(
    result.filesystem_preflight
        .counts
        .conflict == 1
)

assert(
    result.filesystem_preflight
        .counts
        .blocking == 1
)

assert(path_exists(command_marker) == false)
assert(path_exists(ready_destination) == false)

assert(
    path_exists(conflict_destination)
        == true
)

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
    "RC4-D8 OK : un conflit tardif bloque "
        .. "toute mutation avant l’Action 1."
)
