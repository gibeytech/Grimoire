package.path = "./?.lua;./?/init.lua;" .. package.path

local FileOperations = require("installer.file_operations")

print("== FileOperations RC2-C5 Overwrite Apply-Real Test ==")

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
        "Impossible de lire le lien "
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

    assert(
        command_succeeded(
            "mkdir -p -- " .. shell_quote(temporary_path)
        ),
        "Impossible de créer le bac à sable"
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
        "Impossible de nettoyer le bac à sable"
    )
end

local temporary_directory = create_temporary_directory()

local test_ok, test_error = xpcall(function()
    local copy_source = temporary_directory
        .. "/copy source.txt"

    local copy_destination = temporary_directory
        .. "/copy destination.txt"

    local symlink_source_one = temporary_directory
        .. "/symlink source one.txt"

    local symlink_source_two = temporary_directory
        .. "/symlink source two.txt"

    local symlink_destination = temporary_directory
        .. "/symlink destination.txt"

    write_file(copy_source, "nouveau contenu\n")
    write_file(copy_destination, "ancien contenu\n")
    write_file(symlink_source_one, "source un\n")
    write_file(symlink_source_two, "source deux\n")

    assert(path_exists(copy_destination))

    ------------------------------------------------------------------
    -- Copy refusé par défaut
    ------------------------------------------------------------------

    local refused_copy_result = FileOperations.run({
        type = "copy",
        source = copy_source,
        destination = copy_destination,
    }, {
        dry_run = false,
        apply_real = true,
    })

    assert(refused_copy_result.ok == false)
    assert(refused_copy_result.mode == "apply-real")
    assert(refused_copy_result.prepared == true)
    assert(refused_copy_result.simulated == false)
    assert(refused_copy_result.executed == true)
    assert(
        refused_copy_result.error
            == "Échec de l'opération fichier copy : Commande système échouée"
    )

    assert(read_file(copy_destination) == "ancien contenu\n")

    ------------------------------------------------------------------
    -- Copy autorisé avec overwrite
    ------------------------------------------------------------------

    local overwritten_copy_result = FileOperations.run({
        type = "copy",
        source = copy_source,
        destination = copy_destination,
        overwrite = true,
    }, {
        dry_run = false,
        apply_real = true,
    })

    assert(overwritten_copy_result.ok == true)
    assert(overwritten_copy_result.mode == "apply-real")
    assert(overwritten_copy_result.executed == true)
    assert(overwritten_copy_result.error == nil)
    assert(
        overwritten_copy_result.system_result.overwrite
            == true
    )

    assert(read_file(copy_destination) == "nouveau contenu\n")

    ------------------------------------------------------------------
    -- Création du premier lien
    ------------------------------------------------------------------

    local first_symlink_result = FileOperations.run({
        type = "symlink",
        source = symlink_source_one,
        destination = symlink_destination,
    }, {
        dry_run = false,
        apply_real = true,
    })

    assert(first_symlink_result.ok == true)
    assert(symbolic_link_exists(symlink_destination))
    assert(
        read_symlink(symlink_destination)
            == symlink_source_one
    )

    ------------------------------------------------------------------
    -- Remplacement du lien refusé par défaut
    ------------------------------------------------------------------

    local refused_symlink_result = FileOperations.run({
        type = "symlink",
        source = symlink_source_two,
        destination = symlink_destination,
    }, {
        dry_run = false,
        apply_real = true,
    })

    assert(refused_symlink_result.ok == false)
    assert(refused_symlink_result.executed == true)
    assert(
        refused_symlink_result.error
            == "Échec de l'opération fichier symlink : Commande système échouée"
    )

    assert(
        read_symlink(symlink_destination)
            == symlink_source_one
    )

    ------------------------------------------------------------------
    -- Remplacement du lien autorisé
    ------------------------------------------------------------------

    local overwritten_symlink_result = FileOperations.run({
        type = "symlink",
        source = symlink_source_two,
        destination = symlink_destination,
        overwrite = true,
    }, {
        dry_run = false,
        apply_real = true,
    })

    assert(overwritten_symlink_result.ok == true)
    assert(overwritten_symlink_result.executed == true)
    assert(overwritten_symlink_result.error == nil)
    assert(
        overwritten_symlink_result.system_result.overwrite
            == true
    )

    assert(symbolic_link_exists(symlink_destination))
    assert(
        read_symlink(symlink_destination)
            == symlink_source_two
    )
end, debug.traceback)

local cleanup_ok, cleanup_error = pcall(
    remove_temporary_directory,
    temporary_directory
)

if not cleanup_ok then
    error(
        "Échec du nettoyage du bac à sable RC2-C5:\n"
            .. tostring(cleanup_error)
    )
end

if not test_ok then
    error(test_error)
end

assert(not path_exists(temporary_directory))

print("")
print("RC2-C5 OK : overwrite contrôle les conflits copy et symlink.")
