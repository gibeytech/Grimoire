local FilesystemRollback = require(
   "installer.filesystem_rollback"
)

local ShellRollback = {}

local function resolve_mode(options)
   options = options or {}

   if options.dry_run ~= false then
      return "dry-run"
   end

   if options.apply_real == true then
      return "apply-real"
   end

   return "apply-safe"
end

local function invalid_result(
   metadata,
   options,
   error_message
)
   return {
      ok = false,
      mode = resolve_mode(options),
      status = "invalid",
      metadata = metadata,
      compensation_type =
         metadata
         and metadata.compensation_type
         or nil,
      runtime =
         metadata and metadata.runtime or nil,
      destination =
         metadata
         and metadata.destination
         or nil,
      command = nil,
      prepared = false,
      simulated = false,
      executed = false,
      removed = false,
      already_absent = false,
      exit_code = nil,
      reason = nil,
      stdout = "",
      stderr = "",
      filesystem_result = nil,
      error = error_message,
   }
end

local function validate(metadata)
   if type(metadata) ~= "table" then
      return false,
         "Métadonnées Shell invalides"
   end

   if metadata.kind ~= "shell" then
      return false,
         "Type de compensation Shell incompatible"
   end

   if metadata.status ~= "ready"
      or metadata.eligible ~= true
      or metadata.reversible ~= true
   then
      return false,
         "La compensation Shell n'est pas prête"
   end

   if metadata.compensation_type
      ~= "remove-created-runtime"
   then
      return false,
         "Type de rollback Shell inconnu"
   end

   if type(metadata.filesystem)
      ~= "table"
   then
      return false,
         "Compensation filesystem Shell absente"
   end

   if metadata.filesystem.destination
      ~= metadata.destination
   then
      return false,
         "Destination Shell incohérente"
   end

   return true, nil
end

function ShellRollback.run(
   metadata,
   options
)
   options = options or {}

   local valid, validation_error =
      validate(metadata)

   if not valid then
      return invalid_result(
         metadata,
         options,
         validation_error
      )
   end

   print(
      "[ShellRollback] Runtime     : "
         .. tostring(metadata.runtime)
   )

   print(
      "[ShellRollback] Destination : "
         .. tostring(metadata.destination)
   )

   local filesystem_result =
      FilesystemRollback.run(
         metadata.filesystem,
         options
      )

   return {
      ok = filesystem_result.ok == true,
      mode = filesystem_result.mode,
      status = filesystem_result.status,
      metadata = metadata,
      compensation_type =
         metadata.compensation_type,
      runtime = metadata.runtime,
      destination = metadata.destination,
      command = filesystem_result.command,
      prepared =
         filesystem_result.prepared == true,
      simulated =
         filesystem_result.simulated == true,
      executed =
         filesystem_result.executed == true,
      removed =
         filesystem_result.removed == true,
      already_absent =
         filesystem_result.already_absent == true,
      exit_code = filesystem_result.exit_code,
      reason = filesystem_result.reason,
      stdout = filesystem_result.stdout or "",
      stderr = filesystem_result.stderr or "",
      filesystem_result =
         filesystem_result,
      error = filesystem_result.error,
   }
end

return ShellRollback
