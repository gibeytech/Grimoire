package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local Builder = require(
   "installer.builder"
)

local ExecutionPlanBuilder = require(
   "installer.execution_plan_builder"
)

local ShellPreflight = require(
   "installer.shell_preflight"
)

print(
   "== Shell Profile RC4-B4 Real Preflight =="
)

local installation_plan =
   Builder.build("gibeytech")

local execution_plan =
   ExecutionPlanBuilder.build(
      installation_plan,
      {
         dry_run = true,
      }
   )

local shell_action = nil

for _, action in ipairs(
   execution_plan:getActions()
) do
   if action.type == "shell_operation" then
      shell_action = action
      break
   end
end

assert(type(shell_action) == "table")

local result =
   ShellPreflight.run(
      shell_action,
      {
         runtime_command = "quickshell",
      }
   )

assert(
   result.ok == true,
   tostring(result.error)
)

assert(result.deployment_ready == true)
assert(type(result.source_resolved) == "string")
assert(result.source_resolved ~= "")
assert(type(result.entrypoint_path) == "string")
assert(result.entrypoint_path ~= "")
assert(#result.missing_tools == 0)

print(
   "Source      : "
      .. tostring(result.source_resolved)
)

print(
   "Destination : "
      .. tostring(result.destination)
)

print(
   "Entrypoint  : "
      .. tostring(result.entrypoint_path)
)

print(
   "Runtime     : "
      .. tostring(result.runtime_command)
)

print(
   "Disponible  : "
      .. tostring(result.runtime_available)
)

for _, warning in ipairs(result.warnings) do
   print("AVERTISSEMENT : " .. warning)
end

print("")
print(
   "RC4-B4 OK : le profil Shell est prêt à être déployé ; "
      .. "la disponibilité du moteur QML est signalée séparément."
)
