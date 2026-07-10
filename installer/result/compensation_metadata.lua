local CompensationMetadata = {}

local function normalized_operation(operation)
   if type(operation) == "table" then
      return operation
   end

   return {}
end

local function create_base(operation)
   operation = normalized_operation(operation)

   return {
      kind = "filesystem",
      status = "planned",
      eligible = false,
      reversible = false,
      compensation_type = nil,
      operation_type = operation.type,
      source = operation.source,
      destination = operation.destination,
      overwrite = operation.overwrite == true,
      created_destination = nil,
      destination_existed_before = nil,
      previous_destination = nil,
      reason = nil,
   }
end

local function operation_creates_destination(operation)
   return operation.type == "copy"
      or operation.type == "symlink"
end

local function operation_is_eligible(operation)
   return operation_creates_destination(operation)
      and operation.overwrite ~= true
end

local function unsafe_overwrite_reason()
   return "Destination potentiellement remplacée "
      .. "sans sauvegarde préalable"
end

function CompensationMetadata.invalid(operation, reason)
   local metadata = create_base(operation)

   metadata.status = "invalid"
   metadata.reason = reason
      or "Opération filesystem invalide"

   return metadata
end

function CompensationMetadata.prepare(operation)
   operation = normalized_operation(operation)

   local metadata = create_base(operation)

   if operation_is_eligible(operation) then
      metadata.status = "planned"
      metadata.eligible = true
      metadata.compensation_type = "remove-created-path"
      metadata.reason =
         "Compensation disponible après exécution réussie"

      return metadata
   end

   if operation_creates_destination(operation)
      and operation.overwrite == true
   then
      metadata.status = "unsafe"
      metadata.reason = unsafe_overwrite_reason()

      return metadata
   end

   if operation.type == "mkdir" then
      metadata.status = "unsupported"
      metadata.reason =
         "L'état initial du répertoire et des parents "
         .. "créés n'est pas capturé"

      return metadata
   end

   metadata.status = "unsupported"
   metadata.reason =
      "Aucune compensation filesystem définie "
      .. "pour cette opération"

   return metadata
end

function CompensationMetadata.not_executed(
   operation,
   reason
)
   local metadata = CompensationMetadata.prepare(operation)

   metadata.status = "not-executed"
   metadata.reversible = false
   metadata.created_destination = nil
   metadata.destination_existed_before = nil
   metadata.previous_destination = nil
   metadata.reason = reason
      or "L'opération filesystem n'a pas été exécutée"

   return metadata
end

function CompensationMetadata.complete(
   operation,
   execution_result
)
   local metadata = CompensationMetadata.prepare(operation)

   if type(execution_result) ~= "table"
      or execution_result.executed ~= true
   then
      return CompensationMetadata.not_executed(
         operation,
         "Aucun résultat d'exécution exploitable"
      )
   end

   if execution_result.ok ~= true then
      metadata.status = "failed"
      metadata.reversible = false
      metadata.created_destination = nil
      metadata.destination_existed_before = nil
      metadata.previous_destination = nil
      metadata.reason =
         "L'opération a échoué ; l'état final de "
         .. "la destination n'est pas garanti"

      return metadata
   end

   if metadata.eligible then
      metadata.status = "ready"
      metadata.reversible = true
      metadata.created_destination = true
      metadata.destination_existed_before = false
      metadata.previous_destination = nil
      metadata.reason = nil

      return metadata
   end

   if operation_creates_destination(operation)
      and operation.overwrite == true
   then
      metadata.status = "unsafe"
      metadata.reason = unsafe_overwrite_reason()

      return metadata
   end

   return metadata
end

return CompensationMetadata
