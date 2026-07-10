package.path = "./?.lua;./?/init.lua;" .. package.path

local FileOperations = require("installer.file_operations")

print("== FileOperations RC2-C4 Parent Directory Apply-Real Test ==")

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
        type(path) == "string"
            and path:match("^/tmp/") ~= nil,
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
    local source_path = temporary_directory .. "/source file.txt"

    local copy_parent = temporary_directory
        .. "/copy parent"
        .. "/nested directory"

    local copy_destination = copy_parent
        .. "/copied file.txt"

    local symlink_parent = temporary_directory
        .. "/symlink parent"
        .. "/nested directory"

    local symlink_destination = symlink_parent
        .. "/linked file.txt"

    local expected_content = table.concat({
        "Grimoire V3",
        "RC2-C4",
        "Automatic parent directory",
        "",
    }, "\n")

    write_file(source_path, expected_content)

    assert(path_exists(source_path))
    assert(not directory_exists(copy_parent))
    assert(not path_exists(copy_destination))
    assert(not directory_exists(symlink_parent))
    assert(not path_exists(symlink_destination))

    ------------------------------------------------------------------
    -- Copy avec création automatique du parent
    ------------------------------------------------------------------

    local copy_result = FileOperations.run({
        type = "copy",
        source = source_path,
        destination = copy_destination,
    }, {
        dry_run = false,
        apply_real = true,
    })

    assert(copy_result.ok == true)
    assert(copy_result.mode == "apply-real")
    assert(copy_result.prepared == true)
    assert(copy_result.simulated == false)
    assert(copy_result.executed == true)
    assert(copy_result.error == nil)

    assert(type(copy_result.system_result) == "table")
    assert(copy_result.system_result.ok == true)
    assert(copy_result.system_result.executed == true)
    assert(copy_result.system_result.exit_code == 0)
    assert(copy_result.system_result.error == nil)

    assert(
        copy_result.system_result.parent_directory
            == copy_parent
    )

    assert(
        type(copy_result.system_result.parent_result)
            == "table"
    )

    assert(
        copy_result.system_result.parent_result.ok
            == true
    )

    assert(
        copy_result.system_result.parent_result.operation.type
            == "mkdir"
    )

    assert(
        copy_result.system_result.parent_result.operation.destination
            == copy_parent
    )

    assert(
        copy_result.system_result.parent_result.executed
            == true
    )

    assert(
        copy_result.system_result.parent_result.exit_code
            == 0
    )

    assert(directory_exists(copy_parent))
    assert(path_exists(copy_destination))
    assert(
        read_file(copy_destination)
            == expected_content
    )

    ------------------------------------------------------------------
    -- Symlink avec création automatique du parent
    ------------------------------------------------------------------

    local symlink_result = FileOperations.run({
        type = "symlink",
        source = source_path,
        destination = symlink_destination,
    }, {
        dry_run = false,
        apply_real = true,
    })

    assert(symlink_result.ok == true)
    assert(symlink_result.mode == "apply-real")
    assert(symlink_result.prepared == true)
    assert(symlink_result.simulated == false)
    assert(symlink_result.executed == true)
    assert(symlink_result.error == nil)

    assert(type(symlink_result.system_result) == "table")
    assert(symlink_result.system_result.ok == true)
    assert(symlink_result.system_result.executed == true)
    assert(symlink_result.system_result.exit_code == 0)
    assert(symlink_result.system_result.error == nil)

    assert(
        symlink_result.system_result.parent_directory
            == symlink_parent
    )

    assert(
        type(symlink_result.system_result.parent_result)
            == "table"
    )

    assert(
        symlink_result.system_result.parent_result.ok
            == true
    )

    assert(
        symlink_result.system_result.parent_result.operation.type
            == "mkdir"
    )

    assert(
        symlink_result.system_result.parent_result.operation.destination
            == symlink_parent
    )

    assert(
        symlink_result.system_result.parent_result.executed
            == true
    )

    assert(
        symlink_result.system_result.parent_result.exit_code
            == 0
    )

    assert(directory_exists(symlink_parent))
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
end, debug.traceback)

local cleanup_ok, cleanup_error = pcall(
    remove_temporary_directory,
    temporary_directory
)

if not cleanup_ok then
    error(
        "Échec du nettoyage du bac à sable RC2-C4:\n"
            .. tostring(cleanup_error)
    )
end

if not test_ok then
    error(test_error)
end

assert(not directory_exists(temporary_directory))

print("")
print("RC2-C4 OK : copy et symlink créent automatiquement leur parent.")
