package.path = "./?.lua;./?/init.lua;"
   .. package.path

local CompensationMetadata = require(
   "installer.result.compensation_metadata"
)

local FileOperations = require(
   "installer.file_operations"
)

local ExecutionPlan = require(
   "installer.model.execution_plan"
)

local Executor = require("installer.executor")

print("== CompensationMetadata RC3-B1 Contract Test ==")

local function shell_quote(value)
   local string_value = tostring(value)

   return "'" .. string_value:gsub(
      "'",
      "'\\''"
   ) .. "'"
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
   local file, open_error = io.open(path, "wb")

   assert(
      file,
      "Impossible d'écrire "
         .. tostring(path)
         .. ": "
         .. tostring(open_error)
   )

   local written, write_error = file:write(
      content
   )

   assert(
      written,
      "Écriture impossible: "
         .. tostring(write_error)
   )

   file:close()
end

local function assert_metadata(metadata)
   assert(type(metadata) == "table")
   assert(metadata.kind == "filesystem")
   assert(type(metadata.status) == "string")
   assert(type(metadata.eligible) == "boolean")
   assert(type(metadata.reversible) == "boolean")

   assert(
      metadata.compensation_type == nil
         or type(metadata.compensation_type)
            == "string"
   )

   assert(
      metadata.operation_type == nil
         or type(metadata.operation_type)
            == "string"
   )

   assert(
      metadata.created_destination == nil
         or type(metadata.created_destination)
            == "boolean"
   )

   assert(
      metadata.destination_existed_before == nil
         or type(
            metadata.destination_existed_before
         ) == "boolean"
   )

   assert(
      metadata.reason == nil
         or type(metadata.reason) == "string"
   )
end

----------------------------------------------------------------------
-- Métadonnées planifiées
----------------------------------------------------------------------

local planned_copy = CompensationMetadata.prepare({
   type = "copy",
   source = "source.txt",
   destination = "destination.txt",
})

assert_metadata(planned_copy)
assert(planned_copy.status == "planned")
assert(planned_copy.eligible == true)
assert(planned_copy.reversible == false)

assert(
   planned_copy.compensation_type
      == "remove-created-path"
)

assert(planned_copy.operation_type == "copy")
assert(planned_copy.source == "source.txt")
assert(planned_copy.destination == "destination.txt")
assert(planned_copy.overwrite == false)
assert(planned_copy.created_destination == nil)

assert(
   planned_copy.destination_existed_before
      == nil
)

assert(planned_copy.previous_destination == nil)
assert(type(planned_copy.reason) == "string")

----------------------------------------------------------------------
-- Overwrite sans sauvegarde
----------------------------------------------------------------------

local unsafe_overwrite =
   CompensationMetadata.prepare({
      type = "copy",
      source = "source.txt",
      destination = "destination.txt",
      overwrite = true,
   })

assert_metadata(unsafe_overwrite)
assert(unsafe_overwrite.status == "unsafe")
assert(unsafe_overwrite.eligible == false)
assert(unsafe_overwrite.reversible == false)
assert(unsafe_overwrite.compensation_type == nil)
assert(unsafe_overwrite.overwrite == true)

assert(
   unsafe_overwrite.reason:find(
      "sans sauvegarde",
      1,
      true
   ) ~= nil
)

----------------------------------------------------------------------
-- mkdir non réversible en RC3-B1
----------------------------------------------------------------------

local mkdir_metadata =
   CompensationMetadata.prepare({
      type = "mkdir",
      destination = "/tmp/grimoire metadata",
   })

assert_metadata(mkdir_metadata)
assert(mkdir_metadata.status == "unsupported")
assert(mkdir_metadata.eligible == false)
assert(mkdir_metadata.reversible == false)
assert(mkdir_metadata.compensation_type == nil)

----------------------------------------------------------------------
-- Opération invalide
----------------------------------------------------------------------

local invalid_result = FileOperations.run(
   nil,
   {
      dry_run = true,
   }
)

assert(invalid_result.ok == false)
assert(type(invalid_result.compensation) == "table")
assert_metadata(invalid_result.compensation)

assert(
   invalid_result.compensation.status
      == "invalid"
)

assert(
   invalid_result.compensation.reversible
      == false
)

----------------------------------------------------------------------
-- Bac à sable
----------------------------------------------------------------------

local temporary_directory = os.tmpname()

assert(type(temporary_directory) == "string")
assert(temporary_directory:match("^/tmp/") ~= nil)

os.remove(temporary_directory)

assert(
   command_succeeded(
      "mkdir -p -- "
         .. shell_quote(temporary_directory)
   )
)

local source_path =
   temporary_directory .. "/source file.txt"

local copy_destination =
   temporary_directory
      .. "/copy parent/copied file.txt"

local symlink_destination =
   temporary_directory
      .. "/link parent/linked file.txt"

local dry_run_destination =
   temporary_directory .. "/dry run file.txt"

local missing_source =
   temporary_directory .. "/missing file.txt"

local failed_destination =
   temporary_directory .. "/failed file.txt"

local overwrite_destination =
   temporary_directory .. "/overwrite file.txt"

write_file(source_path, "contenu source\n")
write_file(overwrite_destination, "ancien contenu\n")

----------------------------------------------------------------------
-- Dry-run : compensation seulement planifiée
----------------------------------------------------------------------

local dry_run_result = FileOperations.run({
   type = "copy",
   source = source_path,
   destination = dry_run_destination,
   overwrite = false,
}, {
   dry_run = true,
})

assert(dry_run_result.ok == true)
assert(dry_run_result.executed == false)
assert(type(dry_run_result.compensation) == "table")

assert_metadata(dry_run_result.compensation)

assert(
   dry_run_result.compensation.status
      == "planned"
)

assert(
   dry_run_result.compensation.eligible
      == true
)

assert(
   dry_run_result.compensation.reversible
      == false
)

assert(path_exists(dry_run_destination) == false)

----------------------------------------------------------------------
-- Apply-real par le pipeline Executor
----------------------------------------------------------------------

local execution_plan = ExecutionPlan:new({
   profile = {
      id = "compensation-test",
      name = "Compensation Test",
   },
   mode = "apply-real",
   actions = {
      {
         type = "file_operation",
         manager = "assets",
         name = "copy-created-path",
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
         name = "symlink-created-path",
         operation = {
            type = "symlink",
            source = source_path,
            destination = symlink_destination,
            overwrite = false,
         },
      },
   },
})

local execution_result = Executor.execute(
   execution_plan,
   {
      dry_run = false,
      apply_real = true,
   }
)

assert(execution_result.ok == true)
assert(execution_result.executed_actions == 2)
assert(#execution_result.results == 2)
assert(#execution_result.journal == 2)

assert(path_exists(copy_destination) == true)
assert(path_exists(symlink_destination) == true)

----------------------------------------------------------------------
-- Copy réussie
----------------------------------------------------------------------

local copy_operation_result =
   execution_result.results[1].details.operation

local copy_compensation =
   copy_operation_result.compensation

assert_metadata(copy_compensation)
assert(copy_compensation.status == "ready")
assert(copy_compensation.eligible == true)
assert(copy_compensation.reversible == true)

assert(
   copy_compensation.compensation_type
      == "remove-created-path"
)

assert(copy_compensation.operation_type == "copy")
assert(copy_compensation.source == source_path)

assert(
   copy_compensation.destination
      == copy_destination
)

assert(copy_compensation.overwrite == false)

assert(
   copy_compensation.created_destination
      == true
)

assert(
   copy_compensation.destination_existed_before
      == false
)

assert(copy_compensation.previous_destination == nil)
assert(copy_compensation.reason == nil)

local copy_filesystem_result =
   copy_operation_result.system_result

assert(type(copy_filesystem_result) == "table")

assert(
   copy_filesystem_result.compensation
      == copy_compensation
)

assert(
   type(copy_filesystem_result.parent_result)
      == "table"
)

assert(
   type(
      copy_filesystem_result
         .parent_result
         .compensation
   ) == "table"
)

assert(
   copy_filesystem_result
      .parent_result
      .compensation
      .status
      == "unsupported"
)

----------------------------------------------------------------------
-- Symlink réussie
----------------------------------------------------------------------

local symlink_operation_result =
   execution_result.results[2].details.operation

local symlink_compensation =
   symlink_operation_result.compensation

assert_metadata(symlink_compensation)
assert(symlink_compensation.status == "ready")
assert(symlink_compensation.eligible == true)
assert(symlink_compensation.reversible == true)

assert(
   symlink_compensation.compensation_type
      == "remove-created-path"
)

assert(
   symlink_compensation.operation_type
      == "symlink"
)

assert(
   symlink_compensation.destination
      == symlink_destination
)

assert(
   symlink_compensation.created_destination
      == true
)

assert(
   symlink_compensation.destination_existed_before
      == false
)

----------------------------------------------------------------------
-- Journal structuré
----------------------------------------------------------------------

local copy_journal_compensation =
   execution_result.journal[1].compensation

local symlink_journal_compensation =
   execution_result.journal[2].compensation

assert_metadata(copy_journal_compensation)
assert_metadata(symlink_journal_compensation)

assert(copy_journal_compensation.status == "ready")
assert(copy_journal_compensation.reversible == true)

assert(
   copy_journal_compensation.destination
      == copy_destination
)

assert(
   symlink_journal_compensation.status
      == "ready"
)

assert(
   symlink_journal_compensation.reversible
      == true
)

assert(
   symlink_journal_compensation.destination
      == symlink_destination
)

assert(
   copy_journal_compensation
      ~= copy_compensation
)

assert(
   symlink_journal_compensation
      ~= symlink_compensation
)

----------------------------------------------------------------------
-- Échec : état final non garanti
----------------------------------------------------------------------

local failed_result = FileOperations.run({
   type = "copy",
   source = missing_source,
   destination = failed_destination,
   overwrite = false,
}, {
   dry_run = false,
   apply_real = true,
})

assert(failed_result.ok == false)
assert(failed_result.executed == true)
assert(type(failed_result.compensation) == "table")

assert_metadata(failed_result.compensation)

assert(
   failed_result.compensation.status
      == "failed"
)

assert(
   failed_result.compensation.eligible
      == true
)

assert(
   failed_result.compensation.reversible
      == false
)

assert(
   failed_result.compensation
      .created_destination
      == nil
)

assert(
   failed_result.compensation.reason:find(
      "n'est pas garanti",
      1,
      true
   ) ~= nil
)

----------------------------------------------------------------------
-- Overwrite réussi mais non réversible
----------------------------------------------------------------------

local overwrite_result = FileOperations.run({
   type = "copy",
   source = source_path,
   destination = overwrite_destination,
   overwrite = true,
}, {
   dry_run = false,
   apply_real = true,
})

assert(overwrite_result.ok == true)
assert(overwrite_result.executed == true)

assert_metadata(overwrite_result.compensation)

assert(
   overwrite_result.compensation.status
      == "unsafe"
)

assert(
   overwrite_result.compensation.eligible
      == false
)

assert(
   overwrite_result.compensation.reversible
      == false
)

assert(
   overwrite_result.compensation
      .previous_destination
      == nil
)

assert(
   overwrite_result.compensation.reason:find(
      "sans sauvegarde",
      1,
      true
   ) ~= nil
)

----------------------------------------------------------------------
-- Nettoyage du bac à sable
----------------------------------------------------------------------

assert(
   temporary_directory:match("^/tmp/") ~= nil
)

assert(
   command_succeeded(
      "rm -rf -- "
         .. shell_quote(temporary_directory)
   )
)

assert(path_exists(temporary_directory) == false)

print("")
print(
   "RC3-B1 OK : les résultats filesystem exposent "
      .. "des métadonnées de compensation sûres."
)
