package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ProfileLoader = require(
   "core.loader.profile_loader"
)

local ServiceSpec = require(
   "installer.model.service_spec"
)

local ServiceExecutor = require(
   "installer.service_executor"
)

print(
   "== Service Profile RC4-A4 Real Preflight =="
)

local profile =
   ProfileLoader.load("gibeytech")

local definitions, errors =
   ServiceSpec.collect(
      profile:getServices()
   )

assert(
   #errors == 0,
   table.concat(errors, "\n")
)

local failures = {}
local inspected = 0
local optional_absent = 0

for _, definition in ipairs(definitions) do
   local result =
      ServiceExecutor.inspect(
         definition,
         {
            timeout_seconds = 10,
            kill_after_seconds = 2,
            elevate_system = false,
         }
      )

   local label =
      "["
      .. tostring(definition.scope)
      .. "] "
      .. tostring(definition.unit)

   if result.ok then
      inspected = inspected + 1

      local state =
         result.state_before or {}

      local load_state =
         state.load_state

      local unit_file_state =
         state.unit_file_state

      if definition.operation == "enable"
         and load_state ~= "loaded"
      then
         table.insert(
            failures,
            label
               .. " doit être disponible"
               .. " (LoadState="
               .. tostring(load_state)
               .. ")"
         )
      elseif definition.operation == "disable"
         and load_state ~= "loaded"
      then
         optional_absent =
            optional_absent + 1

         print(
            "ABSENT ACCEPTÉ : "
               .. label
               .. " — désactivation demandée"
         )
      else
         print(
            "OK             : "
               .. label
               .. " — "
               .. tostring(unit_file_state)
         )
      end
   elseif definition.operation == "disable"
      and result.timed_out ~= true
      and result.interrupted ~= true
   then
      optional_absent =
         optional_absent + 1

      print(
         "ABSENT ACCEPTÉ : "
            .. label
            .. " — unité non requise"
      )
   else
      table.insert(
         failures,
         label
            .. " : "
            .. tostring(result.error)
      )
   end
end

assert(
   #failures == 0,
   table.concat(failures, "\n")
)

print("")
print("Services déclarés : " .. tostring(#definitions))
print("Services inspectés : " .. tostring(inspected))

print(
   "Absences acceptées : "
      .. tostring(optional_absent)
)

print("")
print(
   "RC4-A4 OK : les services requis du profil "
      .. "sont disponibles sur la machine de référence."
)
