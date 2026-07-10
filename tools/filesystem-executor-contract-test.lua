package.path = "./?.lua;./?/init.lua;" .. package.path

local FilesystemExecutor = require("installer.filesystem_executor")

print("== FilesystemExecutor RC2-C3 Contract Test ==")

----------------------------------------------------------------------
-- Préparation copy
----------------------------------------------------------------------

local copy_operation = {
    type = "copy",
    source = "source file.txt",
    destination = "destination file.txt",
}

local copy_result = FilesystemExecutor.prepare(copy_operation)

assert(copy_result.ok == true)
assert(copy_result.operation == copy_operation)
assert(copy_result.executed == false)
assert(type(copy_result.command) == "string")
assert(copy_result.command ~= "")
assert(copy_result.command:match("^cp %-R %-%- ") ~= nil)
assert(copy_result.command:find("'source file.txt'", 1, true) ~= nil)
assert(copy_result.command:find("'destination file.txt'", 1, true) ~= nil)
assert(copy_result.exit_code == nil)
assert(copy_result.reason == nil)
assert(copy_result.system_result == nil)
assert(copy_result.error == nil)

----------------------------------------------------------------------
-- Préparation symlink
----------------------------------------------------------------------

local symlink_operation = {
    type = "symlink",
    source = "source file.txt",
    destination = "linked file.txt",
}

local symlink_result = FilesystemExecutor.prepare(symlink_operation)

assert(symlink_result.ok == true)
assert(symlink_result.operation == symlink_operation)
assert(symlink_result.executed == false)
assert(type(symlink_result.command) == "string")
assert(symlink_result.command ~= "")
assert(symlink_result.command:match("^ln %-s %-%- ") ~= nil)
assert(symlink_result.command:find("'source file.txt'", 1, true) ~= nil)
assert(symlink_result.command:find("'linked file.txt'", 1, true) ~= nil)
assert(symlink_result.exit_code == nil)
assert(symlink_result.reason == nil)
assert(symlink_result.system_result == nil)
assert(symlink_result.error == nil)

----------------------------------------------------------------------
-- Préparation mkdir
----------------------------------------------------------------------

local mkdir_operation = {
    type = "mkdir",
    destination = "parent directory/child directory",
}

local mkdir_result = FilesystemExecutor.prepare(mkdir_operation)

assert(mkdir_result.ok == true)
assert(mkdir_result.operation == mkdir_operation)
assert(mkdir_result.executed == false)
assert(type(mkdir_result.command) == "string")
assert(mkdir_result.command ~= "")
assert(mkdir_result.command:match("^mkdir %-p %-%- ") ~= nil)
assert(
    mkdir_result.command:find(
        "'parent directory/child directory'",
        1,
        true
    ) ~= nil
)
assert(mkdir_result.exit_code == nil)
assert(mkdir_result.reason == nil)
assert(mkdir_result.system_result == nil)
assert(mkdir_result.error == nil)

----------------------------------------------------------------------
-- Échappement des apostrophes
----------------------------------------------------------------------

local quoted_result = FilesystemExecutor.prepare({
    type = "copy",
    source = "source d'utilisateur.txt",
    destination = "destination d'utilisateur.txt",
})

assert(quoted_result.ok == true)
assert(
    quoted_result.command:find(
        "'source d'\\''utilisateur.txt'",
        1,
        true
    ) ~= nil
)
assert(
    quoted_result.command:find(
        "'destination d'\\''utilisateur.txt'",
        1,
        true
    ) ~= nil
)

local quoted_directory_result = FilesystemExecutor.prepare({
    type = "mkdir",
    destination = "répertoire d'utilisateur",
})

assert(quoted_directory_result.ok == true)
assert(
    quoted_directory_result.command:find(
        "'répertoire d'\\''utilisateur'",
        1,
        true
    ) ~= nil
)

----------------------------------------------------------------------
-- Opération invalide
----------------------------------------------------------------------

local invalid_result = FilesystemExecutor.prepare(nil)

assert(invalid_result.ok == false)
assert(invalid_result.operation == nil)
assert(invalid_result.command == nil)
assert(invalid_result.executed == false)
assert(invalid_result.exit_code == nil)
assert(invalid_result.reason == nil)
assert(invalid_result.system_result == nil)
assert(invalid_result.error == "Opération filesystem invalide")

----------------------------------------------------------------------
-- Type manquant
----------------------------------------------------------------------

local missing_type_result = FilesystemExecutor.prepare({
    source = "source.txt",
    destination = "destination.txt",
})

assert(missing_type_result.ok == false)
assert(missing_type_result.command == nil)
assert(missing_type_result.executed == false)
assert(
    missing_type_result.error
        == "Type d'opération filesystem manquant"
)

----------------------------------------------------------------------
-- Type inconnu
----------------------------------------------------------------------

local unknown_type_result = FilesystemExecutor.prepare({
    type = "delete",
    source = "source.txt",
    destination = "destination.txt",
})

assert(unknown_type_result.ok == false)
assert(unknown_type_result.command == nil)
assert(unknown_type_result.executed == false)
assert(
    unknown_type_result.error
        == "Type d'opération filesystem inconnu: delete"
)

----------------------------------------------------------------------
-- Source manquante pour copy
----------------------------------------------------------------------

local missing_copy_source_result = FilesystemExecutor.prepare({
    type = "copy",
    destination = "destination.txt",
})

assert(missing_copy_source_result.ok == false)
assert(missing_copy_source_result.command == nil)
assert(missing_copy_source_result.executed == false)
assert(
    missing_copy_source_result.error
        == "Source d'opération filesystem manquante"
)

----------------------------------------------------------------------
-- Source manquante pour symlink
----------------------------------------------------------------------

local missing_symlink_source_result = FilesystemExecutor.prepare({
    type = "symlink",
    destination = "destination.txt",
})

assert(missing_symlink_source_result.ok == false)
assert(missing_symlink_source_result.command == nil)
assert(missing_symlink_source_result.executed == false)
assert(
    missing_symlink_source_result.error
        == "Source d'opération filesystem manquante"
)

----------------------------------------------------------------------
-- Destination manquante pour copy
----------------------------------------------------------------------

local missing_copy_destination_result = FilesystemExecutor.prepare({
    type = "copy",
    source = "source.txt",
})

assert(missing_copy_destination_result.ok == false)
assert(missing_copy_destination_result.command == nil)
assert(missing_copy_destination_result.executed == false)
assert(
    missing_copy_destination_result.error
        == "Destination d'opération filesystem manquante"
)

----------------------------------------------------------------------
-- Destination manquante pour symlink
----------------------------------------------------------------------

local missing_symlink_destination_result = FilesystemExecutor.prepare({
    type = "symlink",
    source = "source.txt",
})

assert(missing_symlink_destination_result.ok == false)
assert(missing_symlink_destination_result.command == nil)
assert(missing_symlink_destination_result.executed == false)
assert(
    missing_symlink_destination_result.error
        == "Destination d'opération filesystem manquante"
)

----------------------------------------------------------------------
-- Destination manquante pour mkdir
----------------------------------------------------------------------

local missing_mkdir_destination_result = FilesystemExecutor.prepare({
    type = "mkdir",
})

assert(missing_mkdir_destination_result.ok == false)
assert(missing_mkdir_destination_result.command == nil)
assert(missing_mkdir_destination_result.executed == false)
assert(
    missing_mkdir_destination_result.error
        == "Destination d'opération filesystem manquante"
)

print("")
print("RC2-C3 OK : FilesystemExecutor prépare copy, symlink et mkdir.")
