local ShellSpec = {}

local VALID_STRATEGIES = {
   copy = true,
   symlink = true,
}

local VALID_OVERWRITE_POLICIES = {
   error = true,
   skip = true,
   force = true,
}

local function value_is_present(value)
   return value ~= nil
      and tostring(value) ~= ""
end

local function trim(value)
   return tostring(value):match(
      "^%s*(.-)%s*$"
   )
end

local function normalize_text(
   value,
   label
)
   if not value_is_present(value) then
      return nil,
         tostring(label) .. " manquant"
   end

   local normalized = trim(value)

   if normalized == "" then
      return nil,
         tostring(label) .. " manquant"
   end

   if normalized:find(
      "\0",
      1,
      true
   ) then
      return nil,
         tostring(label) .. " invalide"
   end

   return normalized, nil
end

local function normalize_identifier(
   value,
   label
)
   local normalized, normalize_error =
      normalize_text(
         value,
         label
      )

   if not normalized then
      return nil, normalize_error
   end

   if not normalized:match(
      "^[%w][%w._-]*$"
   ) then
      return nil,
         tostring(label)
            .. " invalide : "
            .. tostring(normalized)
   end

   return normalized, nil
end

local function normalize_modules(value)
   if type(value) ~= "table" then
      return nil,
         "La liste des modules shell doit être une table"
   end

   local modules = {}
   local seen = {}

   for index, module in ipairs(value) do
      local normalized, module_error =
         normalize_identifier(
            module,
            "Module shell[" .. tostring(index) .. "]"
         )

      if not normalized then
         return nil, module_error
      end

      if seen[normalized] then
         return nil,
            "Module shell dupliqué : "
               .. tostring(normalized)
      end

      seen[normalized] = true

      table.insert(
         modules,
         normalized
      )
   end

   if #modules == 0 then
      return nil,
         "Au moins un module shell est requis"
   end

   return modules, nil
end

local function normalize_strategy(value)
   local normalized, normalize_error =
      normalize_text(
         value or "copy",
         "Stratégie de déploiement shell"
      )

   if not normalized then
      return nil, normalize_error
   end

   normalized = normalized:lower()

   if VALID_STRATEGIES[normalized]
      ~= true
   then
      return nil,
         "Stratégie de déploiement shell inconnue : "
            .. tostring(normalized)
   end

   return normalized, nil
end

local function normalize_overwrite(value)
   local normalized, normalize_error =
      normalize_text(
         value or "error",
         "Politique overwrite shell"
      )

   if not normalized then
      return nil, normalize_error
   end

   normalized = normalized:lower()

   if VALID_OVERWRITE_POLICIES[
      normalized
   ] ~= true
   then
      return nil,
         "Politique overwrite shell inconnue : "
            .. tostring(normalized)
   end

   return normalized, nil
end

local function normalize_entrypoint(value)
   local normalized, normalize_error =
      normalize_text(
         value or "shell.qml",
         "Entrypoint shell"
      )

   if not normalized then
      return nil, normalize_error
   end

   if normalized:sub(1, 1) == "/" then
      return nil,
         "L’entrypoint shell doit être relatif"
   end

   for segment in normalized:gmatch(
      "[^/]+"
   ) do
      if segment == ".." then
         return nil,
            "L’entrypoint shell ne peut pas sortir du runtime"
      end
   end

   return normalized, nil
end

local function clone_modules(modules)
   local clone = {}

   for _, module in ipairs(
      modules or {}
   ) do
      table.insert(
         clone,
         module
      )
   end

   return clone
end

function ShellSpec.normalize(config)
   if type(config) ~= "table" then
      return nil,
         "Configuration shell invalide"
   end

   local deployment =
      config.deployment or {}

   if type(deployment) ~= "table" then
      return nil,
         "Configuration de déploiement shell invalide"
   end

   local runtime, runtime_error =
      normalize_identifier(
         config.runtime,
         "Runtime shell"
      )

   if not runtime then
      return nil, runtime_error
   end

   local modules, modules_error =
      normalize_modules(
         config.modules
      )

   if not modules then
      return nil, modules_error
   end

   local source, source_error =
      normalize_text(
         deployment.source
            or config.source,
         "Source shell"
      )

   if not source then
      return nil, source_error
   end

   local destination, destination_error =
      normalize_text(
         deployment.destination
            or config.destination,
         "Destination shell"
      )

   if not destination then
      return nil, destination_error
   end

   local strategy, strategy_error =
      normalize_strategy(
         deployment.strategy
            or config.strategy
      )

   if not strategy then
      return nil, strategy_error
   end

   local overwrite, overwrite_error =
      normalize_overwrite(
         deployment.overwrite
            or config.overwrite
      )

   if not overwrite then
      return nil, overwrite_error
   end

   local entrypoint, entrypoint_error =
      normalize_entrypoint(
         deployment.entrypoint
            or config.entrypoint
      )

   if not entrypoint then
      return nil, entrypoint_error
   end

   return {
      runtime = runtime,
      modules = clone_modules(modules),
      source = source,
      destination = destination,
      strategy = strategy,
      overwrite = overwrite,
      entrypoint = entrypoint,
      explicit = true,
   }, nil
end

function ShellSpec.normalize_action(action)
   if type(action) ~= "table" then
      return nil,
         "Opération shell invalide"
   end

   local legacy =
      action.module ~= nil
      and action.modules == nil
      and action.source == nil
      and action.destination == nil
      and action.deployment == nil

   if legacy then
      local runtime, runtime_error =
         normalize_identifier(
            action.runtime,
            "Runtime shell"
         )

      if not runtime then
         return nil, runtime_error
      end

      local module, module_error =
         normalize_identifier(
            action.module,
            "Module shell"
         )

      if not module then
         return nil, module_error
      end

      return {
         runtime = runtime,
         module = module,
         modules = {
            module,
         },
         source = nil,
         destination = nil,
         strategy = "legacy",
         overwrite = nil,
         entrypoint = nil,
         explicit = false,
      }, nil
   end

   return ShellSpec.normalize(action)
end

function ShellSpec.clone_modules(modules)
   return clone_modules(modules)
end

return ShellSpec
