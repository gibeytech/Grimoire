local ServiceExecutor = require(
   "installer.service_executor"
)

local ServiceRollback = {}

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

local function value_is_present(value)
   return value ~= nil
      and tostring(value) ~= ""
end

local function metadata_is_valid(metadata)
   if type(metadata) ~= "table" then
      return false,
         "Métadonnées de service invalides"
   end

   if metadata.kind ~= "service" then
      return false,
         "Type de compensation incompatible"
   end

   if metadata.status ~= "ready" then
      return false,
         "La compensation service n’est pas prête"
   end

   if metadata.eligible ~= true then
      return false,
         "La compensation service n’est pas éligible"
   end

   if metadata.reversible ~= true then
      return false,
         "La compensation service n’est pas réversible"
   end

   if metadata.compensation_type
      ~= "restore-service-state"
   then
      return false,
         "Type de rollback service inconnu"
   end

   if not value_is_present(metadata.unit) then
      return false,
         "Unité de rollback manquante"
   end

   if metadata.scope ~= "system"
      and metadata.scope ~= "user"
   then
      return false,
         "Scope de rollback invalide"
   end

   if metadata.restore_operation ~= "enable"
      and metadata.restore_operation ~= "disable"
   then
      return false,
         "Opération de restauration invalide"
   end

   if not value_is_present(
      metadata.unit_file_state_before
   ) then
      return false,
         "État systemd initial manquant"
   end

   return true, nil
end

local function executor_options(metadata)
   return {
      systemctl_path =
         metadata.systemctl_path,

      sudo_path =
         metadata.sudo_path,

      elevate_system =
         metadata.elevated == true,

      timeout_seconds =
         metadata.timeout_seconds,

      kill_after_seconds =
         metadata.kill_after_seconds,
   }
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
      kind = metadata
         and metadata.kind
         or nil,
      compensation_type = metadata
         and metadata.compensation_type
         or nil,
      unit = metadata
         and metadata.unit
         or nil,
      scope = metadata
         and metadata.scope
         or nil,
      operation = metadata
         and metadata.restore_operation
         or nil,
      command = nil,
      inspect_command = nil,
      prepared = false,
      simulated = false,
      executed = false,
      restored = false,
      already_restored = false,
      state_before = nil,
      state_after = nil,
      exit_code = nil,
      reason = nil,
      stdout = "",
      stderr = "",
      system = nil,
      runner = nil,
      error = error_message,
   }
end

local function print_rollback(result)
   print(
      "[ServiceRollback] Restauration ["
         .. tostring(result.scope)
         .. "] : "
         .. tostring(result.unit)
   )

   print(
      "[ServiceRollback] Opération    : "
         .. tostring(result.operation)
   )

   print(
      "[ServiceRollback] Commande     : "
         .. tostring(result.command)
   )
end

function ServiceRollback.prepare(
   metadata,
   options
)
   local mode = resolve_mode(options)

   local valid, validation_error =
      metadata_is_valid(metadata)

   if not valid then
      return create_invalid_result(
         metadata,
         mode,
         validation_error
      )
   end

   local runner =
      ServiceExecutor.prepare({
         unit = metadata.unit,
         operation =
            metadata.restore_operation,
         scope = metadata.scope,
      }, executor_options(metadata))

   if not runner.ok then
      return create_invalid_result(
         metadata,
         mode,
         runner.error
      )
   end

   return {
      ok = true,
      mode = mode,
      status = "prepared",
      metadata = metadata,
      kind = metadata.kind,
      compensation_type =
         metadata.compensation_type,
      unit = metadata.unit,
      scope = metadata.scope,
      operation =
         metadata.restore_operation,
      command = runner.command,
      inspect_command =
         runner.inspect_command,
      prepared = true,
      simulated = false,
      executed = false,
      restored = false,
      already_restored = false,
      state_before = nil,
      state_after = nil,
      exit_code = nil,
      reason = nil,
      stdout = "",
      stderr = "",
      system = nil,
      runner = nil,
      error = nil,
   }
end

function ServiceRollback.simulate(result)
   if not result or not result.ok then
      return result
   end

   result.status = "simulated"
   result.simulated = true
   result.executed = false
   result.restored = false
   result.already_restored = false

   print(
      "[ServiceRollback] Simulation : "
         .. tostring(result.mode)
   )

   print_rollback(result)

   return result
end

function ServiceRollback.execute(result)
   if not result or not result.ok then
      return result
   end

   if result.mode ~= "apply-real" then
      return ServiceRollback.simulate(result)
   end

   print(
      "[ServiceRollback] Apply réel : "
         .. "restauration de l’état systemd"
   )

   print_rollback(result)

   local runner =
      ServiceExecutor.execute({
         unit = result.unit,
         operation = result.operation,
         scope = result.scope,
      }, executor_options(result.metadata))

   result.runner = runner
   result.system = runner.system
   result.command = runner.command
   result.inspect_command =
      runner.inspect_command
   result.executed =
      runner.executed == true
   result.exit_code = runner.exit_code
   result.reason = runner.reason
   result.state_before =
      runner.state_before
   result.state_after =
      runner.state_after
   result.simulated = false

   if not runner.ok then
      result.ok = false
      result.status = "failed"
      result.restored = false
      result.already_restored = false
      result.error =
         "Échec du rollback service : "
            .. tostring(runner.error)

      return result
   end

   local final_state =
      runner.state_after
      and runner
         .state_after
         .unit_file_state
      or nil

   if final_state
      ~= result
         .metadata
         .unit_file_state_before
   then
      result.ok = false
      result.status = "state-mismatch"
      result.restored = false
      result.already_restored = false
      result.error =
         "État systemd restauré incompatible : "
            .. tostring(final_state)
            .. " au lieu de "
            .. tostring(
               result
                  .metadata
                  .unit_file_state_before
            )

      return result
   end

   result.ok = true
   result.restored = true
   result.already_restored =
      runner.already_satisfied == true
   result.status =
      result.already_restored
         and "already-restored"
         or "restored"
   result.error = nil

   return result
end

function ServiceRollback.run(
   metadata,
   options
)
   options = options or {}

   local result =
      ServiceRollback.prepare(
         metadata,
         options
      )

   if not result.ok then
      return result
   end

   if result.mode == "dry-run"
      or result.mode == "apply-safe"
   then
      return ServiceRollback.simulate(
         result
      )
   end

   if result.mode == "apply-real" then
      return ServiceRollback.execute(
         result
      )
   end

   return create_invalid_result(
      metadata,
      result.mode,
      "Mode ServiceRollback inconnu : "
         .. tostring(result.mode)
   )
end

return ServiceRollback
