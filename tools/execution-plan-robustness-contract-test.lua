local ProfileLoader = require("core.loader.profile_loader")
local ProfileValidator = require("core.validator.profile_validator")
local Builder = require("installer.builder")
local InstallationPlan = require(
   "installer.model.installation_plan"
)
local InstallationPlanValidator = require(
   "installer.validator.installation_plan_validator"
)
local ExecutionPlanBuilder = require(
   "installer.execution_plan_builder"
)
local ActionDispatcher = require(
   "installer.action_dispatcher"
)

print("== RC3-C3 Execution Plan Robustness Contract Test ==")

local function find_action(actions, manager, name)
   for _, action in ipairs(actions or {}) do
      if action.manager == manager
         and action.name == name
      then
         return action
      end
   end

   return nil
end

-- Le profil réel charge et expose sa configuration de robustesse.
local profile = ProfileLoader.load("gibeytech")
local profile_ok, profile_errors =
   ProfileValidator.validate(profile)

assert(profile_ok == true, table.concat(profile_errors, "\n"))

local robustness = profile:getRobustness()

assert(type(robustness) == "table")
assert(type(robustness.packages) == "table")
assert(robustness.packages.timeout_seconds == 3600)
assert(robustness.packages.kill_after_seconds == 15)
assert(robustness.packages.retry == false)

-- Builder transporte la configuration dans InstallationPlan.
local installation_plan = Builder.build("gibeytech")
local plan_ok, plan_errors =
   InstallationPlanValidator.validate(installation_plan)

assert(plan_ok == true, table.concat(plan_errors, "\n"))
local plan_robustness =
   installation_plan:getRobustness()

assert(type(plan_robustness) == "table")
assert(type(plan_robustness.packages) == "table")
assert(plan_robustness.packages.timeout_seconds == 3600)
assert(plan_robustness.packages.kill_after_seconds == 15)
assert(plan_robustness.packages.retry == false)

-- ExecutionPlanBuilder applique uniquement la politique packages
-- à l'action command produite.
local execution_plan = ExecutionPlanBuilder.build(
   installation_plan,
   {
      dry_run = true,
   }
)

local package_action = find_action(
   execution_plan:getActions(),
   "packages",
   "install-packages"
)

assert(type(package_action) == "table")
assert(package_action.type == "command")
assert(package_action.timeout_seconds == 3600)
assert(package_action.kill_after_seconds == 15)
assert(package_action.retry == false)

for _, action in ipairs(execution_plan:getActions()) do
   if action ~= package_action then
      assert(action.timeout_seconds == nil)
      assert(action.kill_after_seconds == nil)
      assert(action.retry == nil)
   end
end

-- Une politique de retry explicite est clonée dans le plan.
local retry_configuration = {
   replay_safe = true,
   max_attempts = 3,
   exit_codes = { 75 },
   retry_on_timeout = false,
}

local synthetic_plan = InstallationPlan:new({
   profile = {
      id = "rc3-c3",
      name = "RC3-C3",
      version = "1.0.0",
   },
   packages = {
      groups = {
         base = {
            "git",
         },
      },
   },
   robustness = {
      packages = {
         timeout_seconds = 30,
         kill_after_seconds = 2,
         retry = retry_configuration,
      },
   },
})

local synthetic_execution =
   ExecutionPlanBuilder.build(
      synthetic_plan,
      {
         dry_run = true,
      }
   )

local synthetic_action = find_action(
   synthetic_execution:getActions(),
   "packages",
   "install-packages"
)

assert(type(synthetic_action) == "table")
assert(synthetic_action.timeout_seconds == 30)
assert(synthetic_action.kill_after_seconds == 2)
assert(type(synthetic_action.retry) == "table")
assert(synthetic_action.retry ~= retry_configuration)
assert(synthetic_action.retry.exit_codes
   ~= retry_configuration.exit_codes)
assert(synthetic_action.retry.exit_codes[1] == 75)

-- Les contrôles portés par l'action prennent le pas sur
-- les options globales transmises à Executor/Dispatcher.
local dry_run_dispatch = ActionDispatcher.dispatch(
   {
      type = "command",
      manager = "packages",
      name = "action-timeout-precedence",
      command = "true",
      timeout_seconds = 9,
      kill_after_seconds = 1,
   },
   {
      dry_run = true,
      timeout_seconds = 99,
      kill_after_seconds = 20,
   }
)

assert(dry_run_dispatch.ok == true)
assert(
   dry_run_dispatch.details.runner.timeout_seconds
      == 9
)
assert(
   dry_run_dispatch.details.runner.kill_after_seconds
      == 1
)

local timeout_dispatch = ActionDispatcher.dispatch(
   {
      type = "command",
      manager = "packages",
      name = "action-timeout-real",
      command = "sleep 1",
      timeout_seconds = 0.05,
      kill_after_seconds = 0.05,
   },
   {
      dry_run = false,
      apply_real = true,
      timeout_seconds = 2,
      kill_after_seconds = 1,
   }
)

assert(timeout_dispatch.ok == false)
assert(timeout_dispatch.details.runner.timed_out == true)
assert(
   timeout_dispatch.details.runner.timeout_seconds
      == 0.05
)
assert(
   timeout_dispatch.details.runner.kill_after_seconds
      == 0.05
)

print(
   "RC3-C3 OK : les politiques de robustesse du profil "
      .. "alimentent les actions réelles avec priorité locale."
)
