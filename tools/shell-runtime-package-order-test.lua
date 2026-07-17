package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local Builder = require(
    "installer.builder"
)

local ExecutionPlanBuilder = require(
    "installer.execution_plan_builder"
)

local PackageManager = require(
    "installer.managers.package_manager"
)

print(
    "== Shell Runtime RC4-D6 "
        .. "Package Order Test =="
)

local installation_plan =
    Builder.build("gibeytech")

local packages =
    PackageManager.collect_packages(
        installation_plan
    )

assert(type(packages) == "table")
assert(#packages > 0)

local function find_position(values, target)
    for index, value in ipairs(values or {}) do
        if value == target then
            return index
        end
    end

    return nil
end

local hyprland_position =
    find_position(packages, "hyprland")

local quickshell_position =
    find_position(packages, "quickshell")

assert(
    hyprland_position ~= nil,
    "Le paquet hyprland est absent"
)

assert(
    quickshell_position ~= nil,
    "Le paquet quickshell est absent"
)

assert(
    hyprland_position
        < quickshell_position,
    "Quickshell doit être placé après Hyprland"
)

local execution_plan =
    ExecutionPlanBuilder.build(
        installation_plan,
        {
            dry_run = true,
        }
    )

local package_action_position = nil
local shell_action_position = nil
local package_action = nil
local shell_action_count = 0

for index, action in ipairs(
    execution_plan:getActions()
) do
    if action.type == "command"
        and action.manager == "packages"
        and action.name == "install-packages"
    then
        package_action_position = index
        package_action = action
    end

    if action.type == "shell_operation"
        and action.manager == "shell"
        and action.name == "deploy-runtime"
    then
        shell_action_position = index
        shell_action_count =
            shell_action_count + 1
    end
end

assert(
    package_action_position ~= nil,
    "L'action d'installation des paquets est absente"
)

assert(
    shell_action_position ~= nil,
    "L'action de déploiement Shell est absente"
)

assert(
    shell_action_count == 1,
    "Le plan doit contenir une seule action Shell"
)

assert(
    package_action_position
        < shell_action_position,
    "Les paquets doivent être traités avant le Shell"
)

assert(type(package_action.command) == "string")

assert(
    package_action.command:find(
        "quickshell",
        1,
        true
    ) ~= nil,
    "La commande packages ne contient pas quickshell"
)

print("")
print(
    "Paquets               : "
        .. tostring(#packages)
)

print(
    "Hyprland              : position "
        .. tostring(hyprland_position)
)

print(
    "Quickshell            : position "
        .. tostring(quickshell_position)
)

print(
    "Action packages       : position "
        .. tostring(package_action_position)
)

print(
    "Action Shell          : position "
        .. tostring(shell_action_position)
)

print("")
print(
    "RC4-D6 OK : les dépendances précèdent "
        .. "le déploiement du runtime Shell."
)
