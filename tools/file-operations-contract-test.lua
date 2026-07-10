package.path = "./?.lua;./?/init.lua;" .. package.path

local FileOperations = require("installer.file_operations")

print("== FileOperations RC2-C1 Contract Test ==")

local operation = {
    type = "copy",
    source = "source.txt",
    destination = "destination.txt",
}

----------------------------------------------------------------------
-- Prepare
----------------------------------------------------------------------

local prepared_result = FileOperations.prepare(operation, {
    dry_run = true,
})

assert(prepared_result.ok == true)
assert(prepared_result.mode == "dry-run")
assert(prepared_result.operation == operation)
assert(prepared_result.prepared == true)
assert(prepared_result.simulated == false)
assert(prepared_result.executed == false)
assert(type(prepared_result.command) == "string")
assert(prepared_result.command ~= "")
assert(prepared_result.system_result == nil)
assert(prepared_result.error == nil)

----------------------------------------------------------------------
-- Dry-run
----------------------------------------------------------------------

local dry_run_result = FileOperations.run(operation, {
    dry_run = true,
})

assert(dry_run_result.ok == true)
assert(dry_run_result.mode == "dry-run")
assert(dry_run_result.operation == operation)
assert(dry_run_result.prepared == true)
assert(dry_run_result.simulated == true)
assert(dry_run_result.executed == false)
assert(type(dry_run_result.command) == "string")
assert(dry_run_result.command ~= "")
assert(dry_run_result.system_result == nil)
assert(dry_run_result.error == nil)

----------------------------------------------------------------------
-- Apply-safe
----------------------------------------------------------------------

local apply_safe_result = FileOperations.run(operation, {
    dry_run = false,
})

assert(apply_safe_result.ok == true)
assert(apply_safe_result.mode == "apply-safe")
assert(apply_safe_result.operation == operation)
assert(apply_safe_result.prepared == true)
assert(apply_safe_result.simulated == true)
assert(apply_safe_result.executed == false)
assert(type(apply_safe_result.command) == "string")
assert(apply_safe_result.command ~= "")
assert(apply_safe_result.system_result == nil)
assert(apply_safe_result.error == nil)

----------------------------------------------------------------------
-- Construction commande copy
----------------------------------------------------------------------

assert(dry_run_result.command:match("^cp %-R %-%- ") ~= nil)
assert(dry_run_result.command:find("'source.txt'", 1, true) ~= nil)
assert(dry_run_result.command:find("'destination.txt'", 1, true) ~= nil)

----------------------------------------------------------------------
-- Construction commande symlink
----------------------------------------------------------------------

local symlink_operation = {
    type = "symlink",
    source = "source.txt",
    destination = "link.txt",
}

local symlink_result = FileOperations.run(symlink_operation, {
    dry_run = true,
})

assert(symlink_result.ok == true)
assert(symlink_result.mode == "dry-run")
assert(symlink_result.prepared == true)
assert(symlink_result.simulated == true)
assert(symlink_result.executed == false)
assert(type(symlink_result.command) == "string")
assert(symlink_result.command:match("^ln %-s %-%- ") ~= nil)
assert(symlink_result.command:find("'source.txt'", 1, true) ~= nil)
assert(symlink_result.command:find("'link.txt'", 1, true) ~= nil)
assert(symlink_result.system_result == nil)
assert(symlink_result.error == nil)

----------------------------------------------------------------------
-- Opération invalide
----------------------------------------------------------------------

local invalid_result = FileOperations.run({}, {
    dry_run = true,
})

assert(invalid_result.ok == false)
assert(invalid_result.mode == "dry-run")
assert(invalid_result.prepared == false)
assert(invalid_result.simulated == false)
assert(invalid_result.executed == false)
assert(invalid_result.command == nil)
assert(invalid_result.system_result == nil)
assert(invalid_result.error == "Type d'opération fichier manquant")

----------------------------------------------------------------------
-- Type inconnu
----------------------------------------------------------------------

local unknown_type_result = FileOperations.run({
    type = "delete",
    source = "source.txt",
    destination = "destination.txt",
}, {
    dry_run = true,
})

assert(unknown_type_result.ok == false)
assert(unknown_type_result.mode == "dry-run")
assert(unknown_type_result.prepared == false)
assert(unknown_type_result.simulated == false)
assert(unknown_type_result.executed == false)
assert(unknown_type_result.command == nil)
assert(unknown_type_result.system_result == nil)
assert(unknown_type_result.error == "Type d'opération fichier inconnu: delete")

----------------------------------------------------------------------
-- Source manquante
----------------------------------------------------------------------

local missing_source_result = FileOperations.run({
    type = "copy",
    destination = "destination.txt",
}, {
    dry_run = true,
})

assert(missing_source_result.ok == false)
assert(missing_source_result.mode == "dry-run")
assert(missing_source_result.prepared == false)
assert(missing_source_result.simulated == false)
assert(missing_source_result.executed == false)
assert(missing_source_result.command == nil)
assert(missing_source_result.system_result == nil)
assert(missing_source_result.error == "Source d'opération fichier manquante")

----------------------------------------------------------------------
-- Destination manquante
----------------------------------------------------------------------

local missing_destination_result = FileOperations.run({
    type = "copy",
    source = "source.txt",
}, {
    dry_run = true,
})

assert(missing_destination_result.ok == false)
assert(missing_destination_result.mode == "dry-run")
assert(missing_destination_result.prepared == false)
assert(missing_destination_result.simulated == false)
assert(missing_destination_result.executed == false)
assert(missing_destination_result.command == nil)
assert(missing_destination_result.system_result == nil)
assert(missing_destination_result.error == "Destination d'opération fichier manquante")

print("")
print("RC2-C1 OK : FileOperations conserve son contrat et prépare copy/symlink.")
