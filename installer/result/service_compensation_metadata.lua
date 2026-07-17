local ServiceCompensationMetadata = {}

local function state_value(result, state_name, field)
   if type(result) ~= "table"
      or type(result[state_name]) ~= "table"
   then
      return nil
   end

   return result[state_name][field]
end

local function create_base(result)
   result = type(result) == "table"
      and result
      or {}

   return {
      kind = "service",
      status = "planned",
      eligible = false,
      reversible = false,
      compensation_type = nil,

      service = result.service or result.unit,
      unit = result.unit or result.service,
      scope = result.scope,
      operation = result.operation,
      restore_operation = nil,

      load_state_before =
         state_value(
            result,
            "state_before",
            "load_state"
         ),

      unit_file_state_before =
         state_value(
            result,
            "state_before",
            "unit_file_state"
         ),

      load_state_after =
         state_value(
            result,
            "state_after",
            "load_state"
         ),

      unit_file_state_after =
         state_value(
            result,
            "state_after",
            "unit_file_state"
         ),

      systemctl_path = result.systemctl_path,
      sudo_path = result.sudo_path,
      elevated = result.elevated == true,

      timeout_seconds =
         result.timeout_seconds,

      kill_after_seconds =
         result.kill_after_seconds,

      reason = nil,
   }
end

local function resolve_restore_operation(
   operation,
   state_before,
   state_after
)
   if operation == "enable"
      and state_before == "disabled"
      and state_after == "enabled"
   then
      return "disable"
   end

   if operation == "disable"
      and state_before == "enabled"
      and state_after == "disabled"
   then
      return "enable"
   end

   return nil
end

function ServiceCompensationMetadata.invalid(
   result,
   reason
)
   local metadata = create_base(result)

   metadata.status = "invalid"
   metadata.reason = reason
      or "Résultat de service invalide"

   return metadata
end

function ServiceCompensationMetadata.not_executed(
   result,
   reason
)
   local metadata = create_base(result)

   metadata.status = "not-executed"
   metadata.reason = reason
      or "L’opération service n’a pas été exécutée"

   return metadata
end

function ServiceCompensationMetadata.complete(result)
   if type(result) ~= "table" then
      return ServiceCompensationMetadata.invalid(
         result,
         "Résultat ServiceExecutor invalide"
      )
   end

   local metadata = create_base(result)

   if result.already_satisfied == true then
      metadata.status = "not-required"
      metadata.reason =
         "L’état systemd était déjà conforme"

      return metadata
   end

   if result.executed ~= true then
      return ServiceCompensationMetadata.not_executed(
         result
      )
   end

   if result.ok ~= true then
      metadata.status = "failed"
      metadata.reason =
         "L’opération systemd a échoué"

      return metadata
   end

   if result.changed ~= true then
      metadata.status = "not-required"
      metadata.reason =
         "Aucune modification systemd à restaurer"

      return metadata
   end

   local restore_operation =
      resolve_restore_operation(
         metadata.operation,
         metadata.unit_file_state_before,
         metadata.unit_file_state_after
      )

   if not restore_operation then
      metadata.status = "unsupported"
      metadata.reason =
         "La transition systemd ne peut pas être "
            .. "restaurée exactement"

      return metadata
   end

   metadata.status = "ready"
   metadata.eligible = true
   metadata.reversible = true
   metadata.compensation_type =
      "restore-service-state"
   metadata.restore_operation =
      restore_operation
   metadata.reason = nil

   return metadata
end

return ServiceCompensationMetadata
