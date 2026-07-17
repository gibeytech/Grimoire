package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local ShellSpec = require(
   "installer.model.shell_spec"
)

local Builder = require(
   "installer.builder"
)

local ExecutionPlanBuilder = require(
   "installer.execution_plan_builder"
)

print(
   "== ShellSpec RC4-B1 Contract Test =="
)

local contract, contract_error =
   ShellSpec.normalize({
      runtime = "grimoire-shell",

      deployment = {
         source =
            "../grimoire-shell/quickshell",

         destination =
            "~/.config/grimoire-shell",

         strategy = "copy",
         overwrite = "error",
         entrypoint = "shell.qml",
      },

      modules = {
         "bar",
         "hub",
      },
   })

assert(
   contract ~= nil,
   tostring(contract_error)
)

assert(contract.runtime == "grimoire-shell")
assert(#contract.modules == 2)
assert(contract.modules[1] == "bar")

assert(
   contract.source
      == "../grimoire-shell/quickshell"
)

assert(
   contract.destination
      == "~/.config/grimoire-shell"
)

assert(contract.strategy == "copy")
assert(contract.overwrite == "error")
assert(contract.entrypoint == "shell.qml")
assert(contract.explicit == true)

local _, duplicate_error =
   ShellSpec.normalize({
      runtime = "grimoire-shell",
      source = "source",
      destination = "destination",
      modules = {
         "bar",
         "bar",
      },
   })

assert(duplicate_error ~= nil)

local _, strategy_error =
   ShellSpec.normalize({
      runtime = "grimoire-shell",
      source = "source",
      destination = "destination",
      strategy = "mount",
      modules = {
         "bar",
      },
   })

assert(strategy_error ~= nil)

local _, entrypoint_error =
   ShellSpec.normalize({
      runtime = "grimoire-shell",
      source = "source",
      destination = "destination",
      entrypoint = "../shell.qml",
      modules = {
         "bar",
      },
   })

assert(entrypoint_error ~= nil)

local installation_plan =
   Builder.build("gibeytech")

local execution_plan =
   ExecutionPlanBuilder.build(
      installation_plan,
      {
         dry_run = true,
         home = "/home/grimoire-test",
      }
   )

assert(execution_plan:countActions() == 12)

local shell_actions = {}

for _, action in ipairs(
   execution_plan:getActions()
) do
   if action.type == "shell_operation" then
      table.insert(
         shell_actions,
         action
      )
   end
end

assert(#shell_actions == 1)

local action = shell_actions[1]

assert(action.manager == "shell")
assert(action.name == "deploy-runtime")
assert(action.runtime == "grimoire-shell")
assert(#action.modules == 8)

assert(
   action.source
      == "../grimoire-shell/quickshell"
)

assert(
   action.destination
      == "/home/grimoire-test/.config/grimoire-shell"
)

assert(action.strategy == "copy")
assert(action.overwrite == "error")
assert(action.entrypoint == "shell.qml")

print("")
print(
   "RC4-B1 OK : le profil produit une seule "
      .. "action explicite de déploiement du runtime shell."
)
