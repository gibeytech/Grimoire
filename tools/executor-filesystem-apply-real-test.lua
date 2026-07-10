package.path = "./?.lua;./?/init.lua;" .. package.path

local ExecutionPlan = require("installer.model.execution_plan")
local Executor = require("installer.executor")

print("== Executor RC2-E2 Filesystem Apply-Real Integration Test ==")

local function shell_quote(value)
    local string_value = tostring(value)

    return "'" .. string_value:gsub("'", "'\\''") .. "'"
end

local function command_succeeded(command)
    local ok, _, code = os.execute(command)

    if ok == true then
        return true
    end

    if type(ok) == "number" then
        return ok == 0
    end

    if type(code) == "number" then
        return code == 0
    end

    return false
end

local function path_exists(path)
    return command_succeeded(
        "test -e " .. shell_quote(path)
    )
end

local function directory_exists(path)
    return command_succeeded(
        "test -d " .. shell_quote(path)
    )
end

local function symbolic_link_exists(path)
    return command_succeeded(
        "test -L " .. shell_quote(path)
    )
end

local function write_file(path, content)
    local file, open_error = io.open(path, "w")

    assert(
        file ~= nil,
        "Impossible de créer le fichier "
            .. tostring(path)
            .. ": "
            .. tostring(open_error)
    )

    local write_ok, write_error = file:write(content)

    assert(
        write_ok ~= nil,
        "Impossible d'écrire dans le fichier "
            .. tostring(path)
            .. ": "
            .. tostring(write_error)
    )

    file:close()
end

local function read_file(path)
    local file, open_error = io.open(path, "r")

    assert(
        file ~= nil,
        "Impossible d'ouvrir le fichier "
            .. tostring(path)
            .. ": "
            .. tostring(open_error)
    )

    local content = file:read("*a")

    file:close()

    return content
end

local function read_symlink(path)
    local process, open_error = io.popen(
        "readlink -- " .. shell_quote(path),
        "r"
    )

    assert(
        process ~= nil,
        "Impossible de lire le lien symbolique "
            .. tostring(path)
            .. ": "
            .. tostring(open_error)
    )

    local target = process:read("*l")
    local close_ok = process:close()

    assert(
        close_ok == true or close_ok == 0,
        "La commande readlink a échoué pour "
            .. tostring(path)
    )

    return target
end

local function create_temporary_directory()
    local temporary_path = os.tmpname()

    os.remove(temporary_path)

    assert(
        temporary_path:match("^/tmp/") ~= nil,
        "Le bac à sable doit être situé dans /tmp"
    )

    assert(
        command_succeeded(
            "mkdir -p -- " .. shell_quote(temporary_path)
        ),
        "Impossible de créer le bac à sable "
            .. tostring(temporary_path)
    )

    return temporary_path
end

local function remove_temporary_directory(path)
    assert(
        type(path) == "string"
            and path:match("^/tmp/") ~= nil,
        "Refus de nettoyer un chemin situé hors de /tmp"
    )

    assert(
        command_succeeded(
            "rm -rf -- " .. shell_quote(path)
        ),
        "Impossible de nettoyer le bac à sable "
            .. tostring(path)
    )
end

local temporary_directory = create_temporary_directory()

local test_ok, test_error = xpcall(function()
    local source_path = temporary_directory
        .. "/sources"
        .. "/grimoire source.txt"

    local source_parent = temporary_directory
        .. "/sources"

    local copy_destination = temporary_directory
        .. "/deployment"
        .. "/files"
        .. "/grimoire copy.txt"

    local symlink_destination = temporary_directory
        .. "/deployment"
        .. "/links"
        .. "/grimoire link.txt"

    local expected_content = table.concat({
        "Grimoire V3",
        "RC2-E2",
        "ExecutionPlan apply-real",
        "",
    }, "\n")

    assert(
        command_succeeded(
            "mkdir -p -- " .. shell_quote(source_parent)
        )
    )

    write_file(source_path, expected_content)

    assert(path_exists(source_path))
    assert(not path_exists(copy_destination))
    assert(not path_exists(symlink_destination))

    local execution_plan = ExecutionPlan:new({
        profile = {
            id = "rc2-e2-test",
            name = "RC2-E2 Test",
            version = "1.0.0",
            root = temporary_directory,
        },

        mode = "apply-real",

        actions = {
            {
                type = "file_operation",
                manager = "assets",
                name = "integration-copy",
                executed = false,

                operation = {
                    type = "copy",
                    source = source_path,
                    destination = copy_destination,
                    overwrite = false,
                },
            },

            {
                type = "file_operation",
                manager = "deploy",
                name = "integration-symlink",
                executed = false,

                operation = {
                    type = "symlink",
                    source = source_path,
                    destination = symlink_destination,
                    overwrite = false,
                },
            },
        },
    })

    assert(execution_plan.mode == "apply-real")
    assert(execution_plan:countActions() == 2)

    local execution_result = Executor.execute(
        execution_plan,
        {
            dry_run = false,
            apply_real = true,
        }
    )

    ------------------------------------------------------------------
    -- Résultat global
    ------------------------------------------------------------------

    assert(execution_result.ok == true)
    assert(execution_result.mode == "apply-real")
    assert(execution_result.dry_run == false)
    assert(execution_result.executed_actions == 2)
    assert(type(execution_result.results) == "table")
    assert(#execution_result.results == 2)
    assert(execution_result.error == nil)
    assert(execution_result.failed_at == nil)

    ------------------------------------------------------------------
    -- Résultat copy
    ------------------------------------------------------------------

    local copy_result = execution_result.results[1]

    assert(copy_result.ok == true)
    assert(copy_result.manager == "assets")
    assert(copy_result.actions == 1)
    assert(copy_result.dry_run == false)

    assert(type(copy_result.details) == "table")
    assert(copy_result.details.action.name == "integration-copy")

    local copy_operation_result = copy_result.details.operation

    assert(type(copy_operation_result) == "table")
    assert(copy_operation_result.ok == true)
    assert(copy_operation_result.mode == "apply-real")
    assert(copy_operation_result.prepared == true)
    assert(copy_operation_result.simulated == false)
    assert(copy_operation_result.executed == true)
    assert(copy_operation_result.error == nil)

    assert(type(copy_operation_result.system_result) == "table")
    assert(copy_operation_result.system_result.ok == true)
    assert(copy_operation_result.system_result.executed == true)
    assert(copy_operation_result.system_result.exit_code == 0)

    assert(path_exists(copy_destination))
    assert(read_file(copy_destination) == expected_content)

    ------------------------------------------------------------------
    -- Résultat symlink
    ------------------------------------------------------------------

    local symlink_result = execution_result.results[2]

    assert(symlink_result.ok == true)
    assert(symlink_result.manager == "deploy")
    assert(symlink_result.actions == 1)
    assert(symlink_result.dry_run == false)

    assert(type(symlink_result.details) == "table")
    assert(
        symlink_result.details.action.name
            == "integration-symlink"
    )

    local symlink_operation_result =
        symlink_result.details.operation

    assert(type(symlink_operation_result) == "table")
    assert(symlink_operation_result.ok == true)
    assert(symlink_operation_result.mode == "apply-real")
    assert(symlink_operation_result.prepared == true)
    assert(symlink_operation_result.simulated == false)
    assert(symlink_operation_result.executed == true)
    assert(symlink_operation_result.error == nil)

    assert(
        type(symlink_operation_result.system_result)
            == "table"
    )

    assert(symlink_operation_result.system_result.ok == true)
    assert(
        symlink_operation_result.system_result.executed
            == true
    )
    assert(
        symlink_operation_result.system_result.exit_code
            == 0
    )

    assert(path_exists(symlink_destination))
    assert(symbolic_link_exists(symlink_destination))
    assert(
        read_symlink(symlink_destination)
            == source_path
    )
    assert(
        read_file(symlink_destination)
            == expected_content
    )

    ------------------------------------------------------------------
    -- Parents créés automatiquement
    ------------------------------------------------------------------

    assert(
        directory_exists(
            temporary_directory .. "/deployment/files"
        )
    )

    assert(
        directory_exists(
            temporary_directory .. "/deployment/links"
        )
    )
end, debug.traceback)

local cleanup_ok, cleanup_error = pcall(
    remove_temporary_directory,
    temporary_directory
)

if not cleanup_ok then
    error(
        "Échec du nettoyage du bac à sable RC2-E2:\n"
            .. tostring(cleanup_error)
    )
end

if not test_ok then
    error(test_error)
end

assert(not path_exists(temporary_directory))

print("")
print("RC2-E2 OK : l'Executor déploie copy et symlink en apply-real.")
