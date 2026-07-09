package.path = "./?.lua;./?/init.lua;" .. package.path

local ProfileLoader = require("core.loader.profile_loader")
local ProfileValidator = require("core.validator.profile_validator")
local Builder = require("installer.builder")
local InstallationPlanValidator = require("installer.validator.installation_plan_validator")
local ExecutionPlanBuilder = require("installer.execution_plan_builder")
local Preview = require("installer.preview")
local Executor = require("installer.executor")

local profile_name = arg[1] or "gibeytech"
local dry_run_arg = arg[2] or "true"
local dry_run = dry_run_arg ~= "false"

local manifest_path = "profiles/" .. profile_name .. "/manifest.lua"

local function call(module, candidates, ...)
    for _, name in ipairs(candidates) do
        if type(module[name]) == "function" then
            return module[name](...)
        end
    end

    error("Aucune fonction compatible trouvée: " .. table.concat(candidates, ", "))
end

local function assert_ok(result, label)
    if result == false or result == nil then
        error(label .. " a échoué")
    end

    if type(result) == "table" and result.ok == false then
        error(label .. " a échoué: " .. tostring(result.error))
    end

    return result
end

local function manager_label(name)
    local labels = {
        packages = "Packages",
        services = "Services",
        shell = "Grimoire Shell",
        assets = "Assets",
        deploy = "Déploiement",
    }

    return labels[name] or name
end

local function print_manager_details(result)
    local details = result.details or {}

    if result.manager == "packages" and details.packages then
        print("    commande : " .. tostring(result.command))
        print("    paquets  : " .. tostring(#details.packages))
    elseif result.manager == "services" then
        print("    à activer    : " .. tostring(#(details.enabled or {})))
        print("    à désactiver : " .. tostring(#(details.disabled or {})))
    elseif result.manager == "shell" then
        print("    runtime : " .. tostring(details.runtime))
        print("    modules : " .. tostring(#(details.modules or {})))
    elseif result.manager == "assets" then
        print("    assets : " .. tostring(#(details.assets or {})))
    elseif result.manager == "deploy" then
        print("    déploiements : " .. tostring(#(details.deployments or {})))
    end
end

local function print_execution_summary(execution)
    local total_actions = 0

    print("")
    print("== Résumé Grimoire V3 ==")
    print("OK      : " .. tostring(execution.ok))
    print("Dry-run : " .. tostring(execution.dry_run))
    print("Mode    : " .. tostring(execution.mode or "unknown"))

    if execution.failed_at then
        print("Échec   : " .. tostring(execution.failed_at))
        print("Erreur  : " .. tostring(execution.error))
    end

    if type(execution.results) == "table" then
        print("")
        print("Managers:")

        for _, result in ipairs(execution.results) do
            local actions = result.actions or 0
            total_actions = total_actions + actions

            print("  - " .. manager_label(result.manager) .. " : ok=" .. tostring(result.ok) .. " actions=" .. tostring(actions))
            print_manager_details(result)
        end
    end

    print("")
    print("Total actions préparées : " .. tostring(total_actions))
    print("Total actions exécutées : " .. tostring(execution.executed_actions or 0))
end

print("== RC1-24 Vertical Slice ==")
print("Manifest : " .. manifest_path)
print("Dry-run  : " .. tostring(dry_run))
print("")

print("[1/8] Chargement du manifest")
local profile = assert_ok(
    call(ProfileLoader, { "load", "load_profile", "from_file" }, profile_name),
    "Chargement du profile"
)

print("[2/8] Validation du profile")
assert_ok(
    call(ProfileValidator, { "validate", "validate_profile" }, profile),
    "Validation du profile"
)

print("[3/8] Construction du InstallationPlan")
local installation_plan = assert_ok(
    call(Builder, { "build", "build_plan" }, profile_name),
    "Construction du InstallationPlan"
)

print("[4/8] Validation du InstallationPlan")
assert_ok(
    call(InstallationPlanValidator, { "validate", "validate_plan" }, installation_plan),
    "Validation du InstallationPlan"
)

print("[5/8] Construction du ExecutionPlan")
local execution_plan = assert_ok(
    call(ExecutionPlanBuilder, { "build" }, installation_plan, {
        dry_run = dry_run,
    }),
    "Construction du ExecutionPlan"
)

print("[6/8] Preview")
if type(Preview.show) == "function" then
    Preview.show(installation_plan, execution_plan)
elseif type(Preview.render) == "function" then
    print(Preview.render(installation_plan, execution_plan))
elseif type(Preview.summary) == "function" then
    print(Preview.summary(installation_plan, execution_plan))
else
    print("[Preview] Aucune méthode preview trouvée, étape ignorée")
end

print("[7/8] Executor")
local execution = assert_ok(
    call(Executor, { "execute", "run" }, execution_plan, {
        dry_run = dry_run,
    }),
    "Exécution"
)

print("[8/8] Résumé final")
print_execution_summary(execution)

print("")
print("RC1-24 OK : ExecutionPlan branché dans le Vertical Slice.")
