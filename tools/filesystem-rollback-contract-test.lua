package.path = "./?.lua;./?/init.lua;"
   .. package.path

local SystemExecutor = require(
   "installer.system_executor"
)

local FileOperations = require(
   "installer.file_operations"
)

local FilesystemRollback = require(
   "installer.filesystem_rollback"
)

print("== FilesystemRollback RC3-B2 Contract Test ==")

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

local function symbolic_link_exists(path)
   return command_succeeded(
      "test -L " .. shell_quote(path)
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

local function ready_metadata(
   destination,
   operation_type
)
   return {
      kind = "filesystem",
      status = "ready",
      eligible = true,
      reversible = true,
      compensation_type =
         "remove-created-path",
      operation_type =
         operation_type or "copy",
      source = "/tmp/source",
      destination = destination,
      overwrite = false,
      created_destination = true,
      destination_existed_before = false,
      previous_destination = nil,
      reason = nil,
   }
end

local function assert_normalized_result(result)
   assert(type(result) == "table")
   assert(type(result.ok) == "boolean")
   assert(type(result.mode) == "string")
   assert(type(result.status) == "string")
   assert(type(result.prepared) == "boolean")
   assert(type(result.simulated) == "boolean")
   assert(type(result.executed) == "boolean")
   assert(type(result.removed) == "boolean")
   assert(type(result.already_absent) == "boolean")
   assert(type(result.stdout) == "string")
   assert(type(result.stderr) == "string")

   assert(
      result.command == nil
         or type(result.command) == "string"
   )

   assert(
      result.exit_code == nil
         or type(result.exit_code) == "number"
   )

   assert(
      result.reason == nil
         or type(result.reason) == "string"
   )

   assert(
      result.error == nil
         or type(result.error) == "string"
   )
end

local function assert_refused(metadata)
   local result = FilesystemRollback.prepare(
      metadata,
      {
         dry_run = false,
         apply_real = true,
      }
   )

   assert_normalized_result(result)
   assert(result.ok == false)
   assert(result.status == "invalid")
   assert(result.prepared == false)
   assert(result.simulated == false)
   assert(result.executed == false)
   assert(result.removed == false)
   assert(result.already_absent == false)
   assert(result.command == nil)
   assert(type(result.error) == "string")
end

----------------------------------------------------------------------
-- Refus des métadonnées non sûres
----------------------------------------------------------------------

assert_refused(nil)

assert_refused({
   kind = "command",
})

local planned_metadata = ready_metadata(
   "/tmp/planned"
)

planned_metadata.status = "planned"

assert_refused(planned_metadata)

local ineligible_metadata = ready_metadata(
   "/tmp/ineligible"
)

ineligible_metadata.eligible = false

assert_refused(ineligible_metadata)

local irreversible_metadata = ready_metadata(
   "/tmp/irreversible"
)

irreversible_metadata.reversible = false

assert_refused(irreversible_metadata)

local unknown_type_metadata = ready_metadata(
   "/tmp/unknown-type"
)

unknown_type_metadata.compensation_type =
   "restore-backup"

assert_refused(unknown_type_metadata)

assert_refused(
   ready_metadata(
      "/tmp/mkdir",
      "mkdir"
   )
)

local overwrite_metadata = ready_metadata(
   "/tmp/overwrite"
)

overwrite_metadata.overwrite = true

assert_refused(overwrite_metadata)

local not_created_metadata = ready_metadata(
   "/tmp/not-created"
)

not_created_metadata.created_destination = false

assert_refused(not_created_metadata)

local existed_before_metadata = ready_metadata(
   "/tmp/existed-before"
)

existed_before_metadata
   .destination_existed_before = true

assert_refused(existed_before_metadata)

local previous_destination_metadata =
   ready_metadata(
      "/tmp/previous-destination"
   )

previous_destination_metadata
   .previous_destination = "/tmp/backup"

assert_refused(previous_destination_metadata)

assert_refused(
   ready_metadata("relative/path")
)

assert_refused(
   ready_metadata("/")
)

assert_refused(
   ready_metadata(
      "/tmp/rollback/../danger"
   )
)

assert_refused(
   ready_metadata(
      "/tmp/rollback/./danger"
   )
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

local source_directory =
   temporary_directory
      .. "/source directory"

local source_nested_directory =
   source_directory .. "/nested"

local source_nested_file =
   source_nested_directory
      .. "/content.txt"

local copy_destination =
   temporary_directory
      .. "/copy destination d'utilisateur"

local symlink_source =
   temporary_directory
      .. "/symlink source.txt"

local symlink_destination =
   temporary_directory
      .. "/symlink destination.txt"

local failure_target =
   temporary_directory
      .. "/failure target.txt"

assert(
   command_succeeded(
      "mkdir -p -- "
         .. shell_quote(
            source_nested_directory
         )
   )
)

write_file(
   source_nested_file,
   "contenu du répertoire source\n"
)

write_file(
   symlink_source,
   "contenu de la source du lien\n"
)

write_file(
   failure_target,
   "ne doit pas être supprimé\n"
)

----------------------------------------------------------------------
-- Création des destinations compensables
----------------------------------------------------------------------

local copy_result = FileOperations.run({
   type = "copy",
   source = source_directory,
   destination = copy_destination,
   overwrite = false,
}, {
   dry_run = false,
   apply_real = true,
})

assert(copy_result.ok == true)
assert(copy_result.executed == true)
assert(path_exists(copy_destination) == true)

local copy_metadata = copy_result.compensation

assert(type(copy_metadata) == "table")
assert(copy_metadata.status == "ready")
assert(copy_metadata.reversible == true)

local symlink_result = FileOperations.run({
   type = "symlink",
   source = symlink_source,
   destination = symlink_destination,
   overwrite = false,
}, {
   dry_run = false,
   apply_real = true,
})

assert(symlink_result.ok == true)
assert(symlink_result.executed == true)
assert(path_exists(symlink_destination) == true)
assert(symbolic_link_exists(symlink_destination))

local symlink_metadata =
   symlink_result.compensation

assert(type(symlink_metadata) == "table")
assert(symlink_metadata.status == "ready")
assert(symlink_metadata.reversible == true)

----------------------------------------------------------------------
-- Dry-run
----------------------------------------------------------------------

local dry_run_result = FilesystemRollback.run(
   copy_metadata,
   {
      dry_run = true,
   }
)

assert_normalized_result(dry_run_result)
assert(dry_run_result.ok == true)
assert(dry_run_result.mode == "dry-run")
assert(dry_run_result.status == "simulated")
assert(dry_run_result.prepared == true)
assert(dry_run_result.simulated == true)
assert(dry_run_result.executed == false)
assert(dry_run_result.removed == false)
assert(dry_run_result.already_absent == false)
assert(dry_run_result.system_result == nil)
assert(dry_run_result.error == nil)
assert(path_exists(copy_destination) == true)

assert(
   dry_run_result.command:find(
      "rm -rf --",
      1,
      true
   ) ~= nil
)

assert(
   dry_run_result.command:find(
      shell_quote(copy_destination),
      1,
      true
   ) ~= nil
)

----------------------------------------------------------------------
-- Apply-safe
----------------------------------------------------------------------

local apply_safe_result =
   FilesystemRollback.run(
      copy_metadata,
      {
         dry_run = false,
         apply_real = false,
      }
   )

assert_normalized_result(apply_safe_result)
assert(apply_safe_result.ok == true)
assert(apply_safe_result.mode == "apply-safe")
assert(apply_safe_result.status == "simulated")
assert(apply_safe_result.simulated == true)
assert(apply_safe_result.executed == false)
assert(apply_safe_result.removed == false)
assert(path_exists(copy_destination) == true)

----------------------------------------------------------------------
-- Suppression réelle de la copie
----------------------------------------------------------------------

local copy_rollback =
   FilesystemRollback.run(
      copy_metadata,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert_normalized_result(copy_rollback)
assert(copy_rollback.ok == true)
assert(copy_rollback.mode == "apply-real")
assert(copy_rollback.status == "removed")
assert(copy_rollback.prepared == true)
assert(copy_rollback.simulated == false)
assert(copy_rollback.executed == true)
assert(copy_rollback.removed == true)
assert(copy_rollback.already_absent == false)
assert(copy_rollback.exit_code == 0)
assert(copy_rollback.reason == "exit")
assert(copy_rollback.stdout == "")
assert(copy_rollback.stderr == "")
assert(copy_rollback.error == nil)
assert(type(copy_rollback.system_result) == "table")

assert(path_exists(copy_destination) == false)
assert(path_exists(source_directory) == true)
assert(path_exists(source_nested_file) == true)

----------------------------------------------------------------------
-- Suppression réelle du lien symbolique
----------------------------------------------------------------------

local symlink_rollback =
   FilesystemRollback.run(
      symlink_metadata,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert_normalized_result(symlink_rollback)
assert(symlink_rollback.ok == true)
assert(symlink_rollback.status == "removed")
assert(symlink_rollback.executed == true)
assert(symlink_rollback.removed == true)
assert(symlink_rollback.already_absent == false)
assert(symlink_rollback.exit_code == 0)

assert(path_exists(symlink_destination) == false)
assert(path_exists(symlink_source) == true)

----------------------------------------------------------------------
-- Rollback idempotent
----------------------------------------------------------------------

local repeated_rollback =
   FilesystemRollback.run(
      copy_metadata,
      {
         dry_run = false,
         apply_real = true,
      }
   )

assert_normalized_result(repeated_rollback)
assert(repeated_rollback.ok == true)
assert(repeated_rollback.status == "already-absent")
assert(repeated_rollback.executed == true)
assert(repeated_rollback.removed == false)
assert(repeated_rollback.already_absent == true)
assert(repeated_rollback.exit_code == 74)
assert(repeated_rollback.reason == "exit")
assert(repeated_rollback.error == nil)
assert(path_exists(copy_destination) == false)

----------------------------------------------------------------------
-- Propagation d'un échec SystemExecutor
----------------------------------------------------------------------

local failure_metadata = ready_metadata(
   failure_target,
   "copy"
)

local original_execute =
   SystemExecutor.execute

local call_ok, failure_result_or_error =
   xpcall(
      function()
         SystemExecutor.execute = function(command)
            return {
               ok = false,
               command = command,
               executed = true,
               exit_code = 7,
               reason = "exit",
               stdout = "",
               stderr = "échec simulé",
               error = "Commande système échouée",
            }
         end

         return FilesystemRollback.run(
            failure_metadata,
            {
               dry_run = false,
               apply_real = true,
            }
         )
      end,
      debug.traceback
   )

SystemExecutor.execute = original_execute

assert(call_ok, failure_result_or_error)

local failure_result =
   failure_result_or_error

assert_normalized_result(failure_result)
assert(failure_result.ok == false)
assert(failure_result.status == "failed")
assert(failure_result.executed == true)
assert(failure_result.removed == false)
assert(failure_result.already_absent == false)
assert(failure_result.exit_code == 7)
assert(failure_result.stderr == "échec simulé")

assert(
   failure_result.error:find(
      "Échec du rollback filesystem",
      1,
      true
   ) ~= nil
)

assert(path_exists(failure_target) == true)

----------------------------------------------------------------------
-- Nettoyage du bac à sable
----------------------------------------------------------------------

assert(
   temporary_directory:match("^/tmp/") ~= nil
)

assert(
   command_succeeded(
      "rm -rf -- "
         .. shell_quote(
            temporary_directory
         )
   )
)

assert(path_exists(temporary_directory) == false)

print("")
print(
   "RC3-B2 OK : le rollback filesystem "
      .. "supprime uniquement les destinations "
      .. "créées et déclarées réversibles."
)
