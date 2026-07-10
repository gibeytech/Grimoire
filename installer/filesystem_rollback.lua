local SystemExecutor = require(
   "installer.system_executor"
)

local FilesystemRollback = {}

local ALREADY_ABSENT_EXIT_CODE = 74

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

local function shell_quote(value)
   local string_value = tostring(value)

   return "'" .. string_value:gsub(
      "'",
      "'\\''"
   ) .. "'"
end

local function value_is_present(value)
   return value ~= nil
      and tostring(value) ~= ""
end

local function normalize_destination(destination)
   local normalized = tostring(destination)

   while #normalized > 1
      and normalized:sub(-1) == "/"
   do
      normalized = normalized:sub(1, -2)
   end

   return normalized
end

local function destination_is_safe(destination)
   if not value_is_present(destination) then
      return false,
         "Destination de rollback manquante"
   end

   destination = tostring(destination)

   if destination:find("\0", 1, true) then
      return false,
         "Destination de rollback invalide"
   end

   if destination:sub(1, 1) ~= "/" then
      return false,
         "La destination de rollback doit être absolue"
   end

   local normalized = normalize_destination(
      destination
   )

   if normalized == "/" then
      return false,
         "La racine système ne peut pas être supprimée"
   end

   for component in normalized:gmatch("[^/]+") do
      if component == "."
         or component == ".."
      then
         return false,
            "La destination contient un segment dangereux"
      end
   end

   return true, normalized
end

local function metadata_is_valid(metadata)
   if type(metadata) ~= "table" then
      return false,
         "Métadonnées de compensation invalides"
   end

   if metadata.kind ~= "filesystem" then
      return false,
         "Type de compensation incompatible"
   end

   if metadata.status ~= "ready" then
      return false,
         "La compensation filesystem n'est pas prête"
   end

   if metadata.eligible ~= true then
      return false,
         "La compensation filesystem n'est pas éligible"
   end

   if metadata.reversible ~= true then
      return false,
         "La compensation filesystem n'est pas réversible"
   end

   if metadata.compensation_type
      ~= "remove-created-path"
   then
      return false,
         "Type de rollback filesystem inconnu"
   end

   if metadata.operation_type ~= "copy"
      and metadata.operation_type ~= "symlink"
   then
      return false,
         "Opération filesystem non compensable"
   end

   if metadata.overwrite == true then
      return false,
         "Une destination écrasée ne peut pas être supprimée"
   end

   if metadata.created_destination ~= true then
      return false,
         "La destination n'est pas identifiée comme créée"
   end

   if metadata.destination_existed_before
      ~= false
   then
      return false,
         "L'état initial de la destination est incompatible"
   end

   if metadata.previous_destination ~= nil then
      return false,
         "Une destination précédente ne peut pas être ignorée"
   end

   return destination_is_safe(
      metadata.destination
   )
end

local function build_remove_command(destination)
   local quoted_destination = shell_quote(
      destination
   )

   return table.concat({
      "if [ -e",
      quoted_destination,
      "] || [ -L",
      quoted_destination,
      "]; then",
      "rm -rf --",
      quoted_destination .. ";",
      "else",
      "exit",
      tostring(ALREADY_ABSENT_EXIT_CODE) .. ";",
      "fi",
   }, " ")
end

local function create_invalid_result(
   metadata,
   mode,
   error_message
)
   return {
      ok = false,
      mode = mode,
      status = "invalid",
      metadata = metadata,
      compensation_type = metadata
         and metadata.compensation_type
         or nil,
      destination = metadata
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
      system_result = nil,
      error = error_message,
   }
end

local function print_rollback(result)
   print(
      "[FilesystemRollback] Destination : "
         .. tostring(result.destination)
   )

   print(
      "[FilesystemRollback] Commande    : "
         .. tostring(result.command)
   )
end

function FilesystemRollback.prepare(
   metadata,
   options
)
   local mode = resolve_mode(options)

   local valid, destination_or_error =
      metadata_is_valid(metadata)

   if not valid then
      return create_invalid_result(
         metadata,
         mode,
         destination_or_error
      )
   end

   local destination = destination_or_error

   return {
      ok = true,
      mode = mode,
      status = "prepared",
      metadata = metadata,
      compensation_type =
         metadata.compensation_type,
      destination = destination,
      command = build_remove_command(
         destination
      ),
      prepared = true,
      simulated = false,
      executed = false,
      removed = false,
      already_absent = false,
      exit_code = nil,
      reason = nil,
      stdout = "",
      stderr = "",
      system_result = nil,
      error = nil,
   }
end

function FilesystemRollback.simulate(result)
   if not result or not result.ok then
      return result
   end

   result.status = "simulated"
   result.simulated = true
   result.executed = false
   result.removed = false
   result.already_absent = false

   if result.mode == "dry-run" then
      print(
         "[FilesystemRollback] Dry-run : "
            .. "suppression préparée"
      )
   elseif result.mode == "apply-safe" then
      print(
         "[FilesystemRollback] Apply sécurisé : "
            .. "suppression préparée mais non exécutée"
      )
   else
      print(
         "[FilesystemRollback] Simulation : mode "
            .. tostring(result.mode)
      )
   end

   print_rollback(result)

   return result
end

function FilesystemRollback.execute(result)
   if not result or not result.ok then
      return result
   end

   if result.mode ~= "apply-real" then
      return FilesystemRollback.simulate(result)
   end

   print(
      "[FilesystemRollback] Apply réel : "
         .. "suppression de la destination créée"
   )

   print_rollback(result)

   local system_result = SystemExecutor.execute(
      result.command
   )

   result.system_result = system_result
   result.executed =
      system_result.executed == true
   result.exit_code = system_result.exit_code
   result.reason = system_result.reason
   result.stdout = system_result.stdout or ""
   result.stderr = system_result.stderr or ""
   result.simulated = false

   local destination_was_absent =
      system_result.executed == true
      and system_result.exit_code
         == ALREADY_ABSENT_EXIT_CODE
      and system_result.reason == "exit"
      and system_result.error
         == "Commande système échouée"

   if destination_was_absent then
      result.ok = true
      result.status = "already-absent"
      result.removed = false
      result.already_absent = true
      result.error = nil

      return result
   end

   if not system_result.ok then
      result.ok = false
      result.status = "failed"
      result.removed = false
      result.already_absent = false
      result.error =
         "Échec du rollback filesystem: "
            .. tostring(system_result.error)

      return result
   end

   result.ok = true
   result.status = "removed"
   result.removed = true
   result.already_absent = false
   result.error = nil

   return result
end

function FilesystemRollback.run(
   metadata,
   options
)
   options = options or {}

   local result = FilesystemRollback.prepare(
      metadata,
      options
   )

   if not result.ok then
      return result
   end

   if result.mode == "dry-run"
      or result.mode == "apply-safe"
   then
      return FilesystemRollback.simulate(
         result
      )
   end

   if result.mode == "apply-real" then
      return FilesystemRollback.execute(
         result
      )
   end

   return create_invalid_result(
      metadata,
      result.mode,
      "Mode FilesystemRollback inconnu: "
         .. tostring(result.mode)
   )
end

return FilesystemRollback
