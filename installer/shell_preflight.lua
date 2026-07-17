local ShellSpec = require(
   "installer.model.shell_spec"
)

local SystemExecutor = require(
   "installer.system_executor"
)

local ShellPreflight = {}

local DEPLOYMENT_TOOLS = {
   "realpath",
   "test",
   "diff",
   "readlink",
   "rm",
}

local function shell_quote(value)
   return "'"
      .. tostring(value):gsub(
         "'",
         "'\\''"
      )
      .. "'"
end

local function normalize_output(value)
   if value == nil then
      return ""
   end

   return tostring(value):match(
      "^%s*(.-)%s*$"
   ) or ""
end

local function clone_options(options)
   local clone = {}

   for key, value in pairs(options or {}) do
      clone[key] = value
   end

   return clone
end

local function append_unique(values, value)
   for _, existing in ipairs(values) do
      if existing == value then
         return
      end
   end

   table.insert(values, value)
end

local function effective_options(action, options)
   local result = clone_options(options)

   if action.timeout_seconds ~= nil then
      result.timeout_seconds =
         action.timeout_seconds
   end

   if action.kill_after_seconds ~= nil then
      result.kill_after_seconds =
         action.kill_after_seconds
   end

   return result
end

local function run(command, options)
   return SystemExecutor.execute(
      command,
      options
   )
end

local function command_available(
   command,
   options
)
   local result = run(
      "command -v "
         .. shell_quote(command)
         .. " >/dev/null 2>&1",
      options
   )

   return result.ok == true, result
end

local function destination_is_safe(destination)
   if destination == nil
      or tostring(destination) == ""
   then
      return false,
         "Destination Shell manquante"
   end

   local normalized = tostring(destination)

   if normalized:sub(1, 1) ~= "/" then
      return false,
         "La destination Shell doit être absolue"
   end

   while #normalized > 1
      and normalized:sub(-1) == "/"
   do
      normalized = normalized:sub(1, -2)
   end

   if normalized == "/" then
      return false,
         "La racine système ne peut pas accueillir le Shell"
   end

   for component in normalized:gmatch("[^/]+") do
      if component == "."
         or component == ".."
      then
         return false,
            "La destination Shell contient un segment dangereux"
      end
   end

   return true, normalized
end

local function join_path(parent, child)
   local normalized = tostring(parent)

   while #normalized > 1
      and normalized:sub(-1) == "/"
   do
      normalized = normalized:sub(1, -2)
   end

   return normalized .. "/" .. tostring(child)
end

local function invalid_result(
   action,
   error_message
)
   return {
      ok = false,
      deployment_ready = false,
      runtime_available = false,
      runtime_command = nil,
      runtime = action
         and action.runtime
         or nil,
      source = action
         and action.source
         or nil,
      source_resolved = nil,
      destination = action
         and action.destination
         or nil,
      entrypoint = action
         and action.entrypoint
         or nil,
      entrypoint_path = nil,
      strategy = action
         and action.strategy
         or nil,
      tools = {},
      missing_tools = {},
      warnings = {},
      timeout_seconds = action
         and action.timeout_seconds
         or nil,
      kill_after_seconds = action
         and action.kill_after_seconds
         or nil,
      error = error_message,
   }
end

function ShellPreflight.run(action, options)
   options = options or {}

   local contract, contract_error =
      ShellSpec.normalize_action(action)

   if not contract
      or contract.explicit ~= true
   then
      return invalid_result(
         action,
         contract_error
            or "Contrat Shell explicite requis"
      )
   end

   local execution_options =
      effective_options(action, options)

   local result = {
      ok = true,
      deployment_ready = true,
      runtime_available = false,
      runtime_command =
         options.runtime_command
         or "quickshell",
      runtime = contract.runtime,
      source = contract.source,
      source_resolved = nil,
      destination = contract.destination,
      entrypoint = contract.entrypoint,
      entrypoint_path = nil,
      strategy = contract.strategy,
      tools = {},
      missing_tools = {},
      warnings = {},
      timeout_seconds =
         execution_options.timeout_seconds,
      kill_after_seconds =
         execution_options.kill_after_seconds,
      error = nil,
   }

   local required_tools = {}

   for _, command in ipairs(DEPLOYMENT_TOOLS) do
      append_unique(required_tools, command)
   end

   if contract.strategy == "copy" then
      append_unique(required_tools, "cp")
   elseif contract.strategy == "symlink" then
      append_unique(required_tools, "ln")
   end

   for _, command in ipairs(required_tools) do
      local available =
         command_available(
            command,
            execution_options
         )

      result.tools[command] = available

      if not available then
         table.insert(
            result.missing_tools,
            command
         )
      end
   end

   if #result.missing_tools > 0 then
      result.ok = false
      result.deployment_ready = false

      result.error =
         "Outils Shell manquants : "
         .. table.concat(
            result.missing_tools,
            ", "
         )

      return result
   end

   local safe, destination_or_error =
      destination_is_safe(
         contract.destination
      )

   if not safe then
      result.ok = false
      result.deployment_ready = false
      result.error = destination_or_error

      return result
   end

   result.destination = destination_or_error

   local source_result = run(
      "realpath -e -- "
         .. shell_quote(contract.source),
      execution_options
   )

   if not source_result.ok then
      result.ok = false
      result.deployment_ready = false

      result.error =
         "Source Shell introuvable : "
         .. tostring(contract.source)

      return result
   end

   result.source_resolved =
      normalize_output(
         source_result.stdout
      )

   local directory_result = run(
      "test -d "
         .. shell_quote(
            result.source_resolved
         ),
      execution_options
   )

   if not directory_result.ok then
      result.ok = false
      result.deployment_ready = false

      result.error =
         "La source Shell n'est pas un répertoire"

      return result
   end

   result.entrypoint_path =
      join_path(
         result.source_resolved,
         contract.entrypoint
      )

   local entrypoint_result = run(
      "test -f "
         .. shell_quote(
            result.entrypoint_path
         ),
      execution_options
   )

   if not entrypoint_result.ok then
      result.ok = false
      result.deployment_ready = false

      result.error =
         "Entrypoint Shell absent : "
         .. tostring(
            result.entrypoint_path
         )

      return result
   end

   result.runtime_available =
      command_available(
         result.runtime_command,
         execution_options
      )

   if not result.runtime_available then
      table.insert(
         result.warnings,
         "Commande runtime absente : "
            .. tostring(
               result.runtime_command
            )
            .. " — elle devra être fournie "
            .. "par l'installation des paquets"
      )
   end

   return result
end

return ShellPreflight
