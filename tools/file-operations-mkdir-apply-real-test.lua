package.path = "./?.lua;./?/init.lua;" .. package.path

local FileOperations = require("installer.file_operations")

print("== FileOperations RC2-C3 mkdir Apply-Real Test ==")

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

local function directory_exists(path)
    return command_succeeded(
        "test -d " .. shell_quote(path)
    )
end

local function create_temporary_directory()
    local temporary_path = os.tmpname()

    os.remove(temporary_path)

    assert(
        temporary_path:match("^/tmp/") ~= nil,
        "Le répertoire temporaire doit être situé dans /tmp"
    )

    local created = command_succeeded(
        "mkdir -p -- " .. shell_quote(temporary_path)
    )

    assert(
        created,
        "Impossible de créer le bac à sable "
            .. tostring(temporary_path)
    )

    return temporary_path
end

local function remove_temporary_directory(path)
    assert(
        type(path) == "string" and path:match("^/tmp/") ~= nil,
        "Refus de nettoyer un chemin situé hors de /tmp"
    )

    local removed = command_succeeded(
        "rm -rf -- " .. shell_quote(path)
    )

    assert(
        removed,
        "Impossible de nettoyer le bac à sable "
            .. tostring(path)
    )
end

local temporary_directory = create_temporary_directory()

local test_ok, test_error = xpcall(function()
    local nested_directory = temporary_directory
        .. "/parent directory"
        .. "/child directory"

    assert(not directory_exists(nested_directory))

    ------------------------------------------------------------------
    -- Dry-run
    ------------------------------------------------------------------

    local dry_run_result = FileOperations.run({
        type = "mkdir",
        destination = nested_directory,
    }, {
        dry_run = true,
    })

    assert(dry_run_result.ok == true)
    assert(dry_run_result.mode == "dry-run")
    assert(dry_run_result.prepared == true)
    assert(dry_run_result.simulated == true)
    assert(dry_run_result.executed == false)
    assert(type(dry_run_result.command) == "string")
    assert(dry_run_result.command:match("^mkdir %-p %-%- ") ~= nil)
    assert(dry_run_result.system_result == nil)
    assert(dry_run_result.error == nil)

    assert(not directory_exists(nested_directory))

    ------------------------------------------------------------------
    -- Apply-safe
    ------------------------------------------------------------------

    local apply_safe_result = FileOperations.run({
        type = "mkdir",
        destination = nested_directory,
    }, {
        dry_run = false,
    })

    assert(apply_safe_result.ok == true)
    assert(apply_safe_result.mode == "apply-safe")
    assert(apply_safe_result.prepared == true)
    assert(apply_safe_result.simulated == true)
    assert(apply_safe_result.executed == false)
    assert(type(apply_safe_result.command) == "string")
    assert(apply_safe_result.command:match("^mkdir %-p %-%- ") ~= nil)
    assert(apply_safe_result.system_result == nil)
    assert(apply_safe_result.error == nil)

    assert(not directory_exists(nested_directory))

    ------------------------------------------------------------------
    -- Apply-real
    ------------------------------------------------------------------

    local apply_real_result = FileOperations.run({
        type = "mkdir",
        destination = nested_directory,
    }, {
        dry_run = false,
        apply_real = true,
    })

    assert(apply_real_result.ok == true)
    assert(apply_real_result.mode == "apply-real")
    assert(apply_real_result.prepared == true)
    assert(apply_real_result.simulated == false)
    assert(apply_real_result.executed == true)
    assert(type(apply_real_result.command) == "string")
    assert(apply_real_result.command:match("^mkdir %-p %-%- ") ~= nil)
    assert(type(apply_real_result.system_result) == "table")
    assert(apply_real_result.system_result.ok == true)
    assert(apply_real_result.system_result.executed == true)
    assert(apply_real_result.system_result.exit_code == 0)
    assert(apply_real_result.system_result.error == nil)
    assert(apply_real_result.error == nil)

    assert(directory_exists(nested_directory))

    ------------------------------------------------------------------
    -- Idempotence mkdir -p
    ------------------------------------------------------------------

    local repeated_result = FileOperations.run({
        type = "mkdir",
        destination = nested_directory,
    }, {
        dry_run = false,
        apply_real = true,
    })

    assert(repeated_result.ok == true)
    assert(repeated_result.mode == "apply-real")
    assert(repeated_result.prepared == true)
    assert(repeated_result.simulated == false)
    assert(repeated_result.executed == true)
    assert(type(repeated_result.system_result) == "table")
    assert(repeated_result.system_result.ok == true)
    assert(repeated_result.system_result.exit_code == 0)
    assert(repeated_result.error == nil)

    assert(directory_exists(nested_directory))
end, debug.traceback)

local cleanup_ok, cleanup_error = pcall(
    remove_temporary_directory,
    temporary_directory
)

if not cleanup_ok then
    error(
        "Échec du nettoyage du bac à sable RC2-C3:\n"
            .. tostring(cleanup_error)
    )
end

if not test_ok then
    error(test_error)
end

assert(not directory_exists(temporary_directory))

print("")
print("RC2-C3 OK : mkdir fonctionne en apply-real dans /tmp.")
