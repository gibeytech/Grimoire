local ShellSpec = require(
   "installer.model.shell_spec"
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
      module = action.module,
      modules =
         clone_modules(
            action.modules
         ),
      runtime = action.runtime,
      source = action.source,
      destination = action.destination,
      strategy = action.strategy,
      overwrite = action.overwrite,
      entrypoint = action.entrypoint,
      explicit = false,
      prepared = false,
      simulated = false,
      executed = false,
      command = nil,
      reason = nil,
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
      module = contract.module,
      modules =
         clone_modules(
            contract.modules
         ),
      runtime = contract.runtime,
      source = contract.source,
      destination =
         contract.destination,
      strategy = contract.strategy,
      overwrite = contract.overwrite,
      entrypoint = contract.entrypoint,
      explicit =
         contract.explicit == true,
      prepared = true,
      simulated = false,
      executed = false,
      command = nil,
      reason = nil,
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

   result.simulated = true
   result.executed = false

   print_contract(result)

   if result.mode == "dry-run" then
      result.reason = "dry-run"

      print(
         "[ShellOperation] Dry-run : "
            .. "aucun déploiement shell exécuté"
      )
   elseif result.mode == "apply-safe" then
      result.reason = "apply-safe-blocked"

      print(
         "[ShellOperation] Apply sécurisé : "
            .. "runtime préparé mais non déployé"
      )

      print(
         "[ShellOperation] Action shell "
            .. "bloquée volontairement en RC4-B1"
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

function ShellOperation.execute(result)
   if not result or not result.ok then
      return result
   end

   if result.mode ~= "apply-real" then
      return ShellOperation.simulate(
         result
      )
   end

   print_contract(result)

   result.ok = false
   result.simulated = false
   result.executed = false
   result.reason = "apply-real-blocked"

   result.error =
      "Mode apply-real non activé en RC4-B1"

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
         result
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
