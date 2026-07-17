local ShellCompensationMetadata = {}

local function clone_filesystem_metadata(metadata)
   if type(metadata) ~= "table" then
      return nil
   end

   local clone = {}

   for key, value in pairs(metadata) do
      clone[key] = value
   end

   return clone
end

local function create_base(result)
   result = type(result) == "table"
      and result
      or {}

   return {
      kind = "shell",
      status = "invalid",
      eligible = false,
      reversible = false,
      compensation_type = nil,
      runtime = result.runtime,
      strategy = result.strategy,
      source =
         result.source_resolved
         or result.source,
      destination = result.destination,
      entrypoint = result.entrypoint,
      created_destination = nil,
      destination_existed_before = nil,
      filesystem = nil,
      reason = nil,
   }
end

function ShellCompensationMetadata.invalid(
   result,
   reason
)
   local metadata = create_base(result)

   metadata.status = "invalid"
   metadata.reason =
      reason or "Résultat Shell invalide"

   return metadata
end

function ShellCompensationMetadata.not_executed(
   result,
   reason
)
   local metadata = create_base(result)

   metadata.status = "not-executed"
   metadata.reason =
      reason
      or "Le déploiement Shell n'a pas été exécuté"

   return metadata
end

function ShellCompensationMetadata.complete(result)
   if type(result) ~= "table" then
      return ShellCompensationMetadata.invalid(
         result,
         "Résultat Shell invalide"
      )
   end

   if result.executed ~= true
      or result.changed ~= true
   then
      return ShellCompensationMetadata.not_executed(
         result,
         result.already_satisfied
            and "Le runtime Shell était déjà conforme"
            or "Aucune mutation Shell compensable"
      )
   end

   local filesystem =
      result.compensation

   if type(filesystem) ~= "table" then
      return ShellCompensationMetadata.invalid(
         result,
         "Compensation filesystem Shell absente"
      )
   end

   local metadata = create_base(result)

   metadata.filesystem =
      clone_filesystem_metadata(
         filesystem
      )

   metadata.created_destination =
      filesystem.created_destination

   metadata.destination_existed_before =
      filesystem.destination_existed_before

   if filesystem.status == "ready"
      and filesystem.eligible == true
      and filesystem.reversible == true
      and filesystem.compensation_type
         == "remove-created-path"
   then
      metadata.status = "ready"
      metadata.eligible = true
      metadata.reversible = true

      metadata.compensation_type =
         "remove-created-runtime"

      metadata.reason = nil

      return metadata
   end

   metadata.status =
      filesystem.status or "unsupported"

   metadata.reason =
      filesystem.reason
      or "Le déploiement Shell n'est pas réversible"

   return metadata
end

return ShellCompensationMetadata
