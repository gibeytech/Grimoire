package.path = "./?.lua;./?/init.lua;" .. package.path

local ProfileLoader = require("core.loader.profile_loader")
local ProfileValidator = require("core.validator.profile_validator")
local Builder = require("installer.builder")
local InstallationPlanValidator = require("installer.validator.installation_plan_validator")
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

print("== RC1-10 Vertical Slice ==")
print("Manifest : " .. manifest_path)
print("Dry-run  : " .. tostring(dry_run))
print("")

print("[1/7] Chargement du manifest")
local profile = assert_ok(
    call(ProfileLoader, { "load", "load_profile", "from_file" }, profile_name),
    "Chargement du profile"
)

print("[2/7] Validation du profile")
assert_ok(
    call(ProfileValidator, { "validate", "validate_profile" }, profile),
    "Validation du profile"
)

print("[3/7] Construction du plan")
local plan = assert_ok(
    call(Builder, { "build", "build_plan" }, profile_name),
    "Construction du plan"
)

print("[4/7] Validation du plan")
assert_ok(
    call(InstallationPlanValidator, { "validate", "validate_plan" }, plan),
    "Validation du plan"
)

print("[5/7] Preview")
if type(Preview.show) == "function" then
    Preview.show(plan)
elseif type(Preview.render) == "function" then
    Preview.render(plan)
elseif type(Preview.print) == "function" then
    Preview.print(plan)
elseif type(Preview.preview) == "function" then
    Preview.preview(plan)
else
    print("[Preview] Aucune méthode preview trouvée, étape ignorée")
end

print("[6/7] Executor")
local execution = assert_ok(
    call(Executor, { "execute", "run" }, plan, {
        dry_run = dry_run,
    }),
    "Exécution"
)

print("[7/7] Résumé final")
print("")
print("== Résumé Grimoire V3 ==")
print("OK      : " .. tostring(execution.ok))
print("Dry-run : " .. tostring(execution.dry_run))

if type(execution.results) == "table" then
    print("Managers:")

    for _, result in ipairs(execution.results) do
        print("  - " .. result.manager .. " : ok=" .. tostring(result.ok) .. " actions=" .. tostring(result.actions or 0))
    end
end

print("")
print("RC1-10 OK : Vertical Slice complet en dry-run.")
