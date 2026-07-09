package.path = "./?.lua;./?/init.lua;" .. package.path

local ProfileLoader = require("core.loader.profile_loader")
local ProfileValidator = require("core.validator.profile_validator")
local Builder = require("installer.builder")
local InstallationPlanValidator = require("installer.validator.installation_plan_validator")
local ExecutionPlanBuilder = require("installer.execution_plan_builder")
local SummaryBuilder = require("installer.summary_builder")
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

local function summary_value(summary, section, key, fallback)
    fallback = fallback or 0

    if not summary[section] then
        return fallback
    end

    if summary[section][key] == nil then
        return fallback
    end

    return summary[section][key]
end

local function print_execution_summary(execution)
    local summary = SummaryBuilder.build(execution.results or {})
    local total_actions = #(execution.results or {})

    print("")
    print("== Résumé Grimoire V3 ==")
    print("OK      : " .. tostring(execution.ok))
    print("Dry-run : " .. tostring(execution.dry_run))
    print("Mode    : " .. tostring(execution.mode or "unknown"))

    if execution.failed_at then
        print("Échec   : " .. tostring(execution.failed_at))
        print("Erreur  : " .. tostring(execution.error))
    end

    print("")
    print("Packages")
    print("---------")
    print("Actions  : " .. tostring(summary_value(summary, "packages", "actions")))

    if summary.packages and summary.packages.command then
        print("Commande : " .. tostring(summary.packages.command))
    end

    print("")
    print("Services")
    print("---------")
    print("Enable  : " .. tostring(summary_value(summary, "services", "enable")))
    print("Disable : " .. tostring(summary_value(summary, "services", "disable")))

    print("")
    print("Shell")
    print("------")
    print("Modules : " .. tostring(summary_value(summary, "shell", "modules")))

    if summary.shell and summary.shell.runtime then
        print("Runtime : " .. tostring(summary.shell.runtime))
    end

    print("")
    print("Fichiers")
    print("--------")
    print("Copies : " .. tostring(summary_value(summary, "assets", "copies")))
    print("Liens  : " .. tostring(summary_value(summary, "deploy", "symlinks")))

    print("")
    print("Total actions préparées : " .. tostring(total_actions))
    print("Total actions exécutées : " .. tostring(execution.executed_actions or 0))
end

print("== RC1-25 Vertical Slice ==")
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
print("RC1-25 OK : Résumé final basé sur SummaryBuilder.")
