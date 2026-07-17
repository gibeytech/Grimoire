local ShellSpec = require(
   "installer.model.shell_spec"
)

local ShellDeploymentExecutor = require(
   "installer.shell_deployment_executor"
)

local ShellOperation = {}

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

local function clone_modules(modules)
   return ShellSpec.clone_modules(
      modules
   )
end

local function create_failure(
   action,
   mode,
   error_message
)
   action = type(action) == "table"
      and action
      or {}

   return {
      ok = false,
      mode = mode,
      status = "invalid",
      module = action.module,
      modules =
         clone_modules(
            action.modules
         ),
      runtime = action.runtime,
      source = action.source,
      source_resolved = nil,
      destination = action.destination,
      destination_state = nil,
      strategy = action.strategy,
      overwrite = action.overwrite,
      entrypoint = action.entrypoint,
      explicit = false,
      prepared = false,
      simulated = false,
      executed = false,
      changed = false,
      already_satisfied = false,
      skipped = false,
      command = nil,
      exit_code = nil,
      reason = nil,
      stdout = "",
      stderr = "",
      timed_out = false,
      interrupted = false,
      timeout_seconds = nil,
      kill_after_seconds = nil,
      system_result = nil,
      verification_result = nil,
      compensation = nil,
      error = error_message,
   }
end

local function create_result(
   contract,
   mode
)
   return {
      ok = true,
      mode = mode,
      status = "prepared",
      module = contract.module,
      modules =
         clone_modules(
            contract.modules
         ),
      runtime = contract.runtime,
      source = contract.source,
      source_resolved = nil,
      destination =
         contract.destination,
      destination_state = nil,
      strategy = contract.strategy,
      overwrite = contract.overwrite,
      entrypoint = contract.entrypoint,
      explicit =
         contract.explicit == true,
      prepared = true,
      simulated = false,
      executed = false,
      changed = false,
      already_satisfied = false,
      skipped = false,
      command = nil,
      exit_code = nil,
      reason = nil,
      stdout = "",
      stderr = "",
      timed_out = false,
      interrupted = false,
      timeout_seconds = nil,
      kill_after_seconds = nil,
      system_result = nil,
      verification_result = nil,
      compensation = nil,
      error = nil,
   }
end

local function print_contract(result)
   print(
      "[ShellOperation] Runtime     : "
         .. tostring(result.runtime)
   )

   print(
      "[ShellOperation] Modules     : "
         .. tostring(
            #(result.modules or {})
         )
   )

   if result.explicit == true then
      print(
         "[ShellOperation] Source      : "
            .. tostring(result.source)
      )

      print(
         "[ShellOperation] Destination : "
            .. tostring(
               result.destination
            )
      )

      print(
         "[ShellOperation] Stratégie   : "
            .. tostring(result.strategy)
      )

      print(
         "[ShellOperation] Entrypoint  : "
            .. tostring(result.entrypoint)
      )
   elseif result.module then
      print(
         "[ShellOperation] Module      : "
            .. tostring(result.module)
      )
   end
end

local function apply_deployment_result(
   result,
   deployment
)
   local fields = {
      "ok",
      "status",
      "source_resolved",
      "destination",
      "destination_state",
      "operation",
      "executed",
      "changed",
      "already_satisfied",
      "skipped",
      "command",
      "exit_code",
      "reason",
      "stdout",
      "stderr",
      "timed_out",
      "interrupted",
      "timeout_seconds",
      "kill_after_seconds",
      "system_result",
      "verification_result",
      "compensation",
      "error",
   }

   for _, field in ipairs(fields) do
      result[field] =
         deployment[field]
   end

   result.simulated = false

   return result
end

function ShellOperation.prepare(
   action,
   options
)
   local mode = resolve_mode(options)

   local contract, contract_error =
      ShellSpec.normalize_action(
         action
      )

   if not contract then
      return create_failure(
         action,
         mode,
         contract_error
            or "Opération shell invalide"
      )
   end

   return create_result(
      contract,
      mode
   )
end

function ShellOperation.simulate(result)
   if not result or not result.ok then
      return result
   end

   result.status = "simulated"
   result.simulated = true
   result.executed = false
   result.changed = false
   result.already_satisfied = false
   result.skipped = false

   print_contract(result)

   if result.mode == "dry-run" then
      result.reason = "dry-run"

      print(
         "[ShellOperation] Dry-run : "
            .. "aucun déploiement shell exécuté"
      )
   elseif result.mode == "apply-safe" then
      result.reason =
         "apply-safe-blocked"

      print(
         "[ShellOperation] Apply sécurisé : "
            .. "runtime préparé mais non déployé"
      )

      print(
         "[ShellOperation] Action shell "
            .. "bloquée volontairement"
      )
   else
      result.reason = "simulation"

      print(
         "[ShellOperation] Simulation : mode "
            .. tostring(result.mode)
      )
   end

   return result
end

function ShellOperation.execute(
   result,
   options
)
   if not result or not result.ok then
      return result
   end

   if result.mode ~= "apply-real" then
      return ShellOperation.simulate(
         result
      )
   end

   if result.explicit ~= true then
      result.ok = false
      result.status = "unsupported"
      result.reason =
         "legacy-apply-real-unsupported"

      result.error =
         "Le format Shell hérité ne peut pas être déployé réellement"

      return result
   end

   print_contract(result)

   local deployment =
      ShellDeploymentExecutor.run(
         result,
         options
      )

   result =
      apply_deployment_result(
         result,
         deployment
      )

   if result.ok
      and result.already_satisfied
   then
      print(
         "[ShellOperation] État déjà conforme"
      )
   elseif result.ok
      and result.skipped
   then
      print(
         "[ShellOperation] Destination ignorée"
      )
   elseif result.ok then
      print(
         "[ShellOperation] Runtime déployé et vérifié"
      )
   else
      print(
         "[ShellOperation] Échec : "
            .. tostring(result.error)
      )
   end

   return result
end

function ShellOperation.run(
   action,
   options
)
   options = options or {}

   local result =
      ShellOperation.prepare(
         action,
         options
      )

   if not result.ok then
      return result
   end

   if result.mode == "dry-run"
      or result.mode == "apply-safe"
   then
      return ShellOperation.simulate(
         result
      )
   end

   if result.mode == "apply-real" then
      return ShellOperation.execute(
         result,
         options
      )
   end

   return create_failure(
      action,
      result.mode,
      "Mode ShellOperation inconnu : "
         .. tostring(result.mode)
   )
end

return ShellOperation
