package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local Builder = require(
    "installer.builder"
)

local ExecutionPlanBuilder = require(
    "installer.execution_plan_builder"
)

local ActionDispatcher = require(
    "installer.action_dispatcher"
)

print(
    "== Profile RC4-D10A3 "
        .. "Hypr Activation Plan Test =="
)

local home = assert(os.getenv("HOME"))

local execution_plan =
    ExecutionPlanBuilder.build(
        Builder.build("gibeytech"),
        {
            dry_run = true,
        }
    )

local actions =
    execution_plan:getActions()

assert(#actions == 19)

local loader_action = nil
local loader_sequence = nil

local grimoire_action = nil
local grimoire_sequence = nil

local activation = nil
local activation_sequence = nil

for sequence, action in ipairs(actions) do
    if action.manager == "deploy"
        and action.name
            == "hypr-grimoire-loader"
    then
        loader_action = action
        loader_sequence = sequence
    elseif action.manager == "deploy"
        and action.name == "grimoire"
    then
        grimoire_action = action
        grimoire_sequence = sequence
    elseif action.type
        == "hypr_activation"
    then
        activation = action
        activation_sequence = sequence
    end
end

assert(type(loader_action) == "table")
assert(type(grimoire_action) == "table")
assert(type(activation) == "table")

assert(loader_sequence == 11)
assert(grimoire_sequence == 18)
assert(activation_sequence == 19)

assert(loader_sequence < activation_sequence)
assert(grimoire_sequence < activation_sequence)

assert(activation.manager == "deploy")
assert(activation.name == "activate-hypr")

assert(
    activation.destination
        == home
            .. "/.config/hypr/hyprland.lua"
)

assert(
    activation.loader
        == home
            .. "/.config/hypr/"
            .. "grimoire-loader.lua"
)

assert(
    activation.loader_source
        == "config/hypr/grimoire-loader.lua"
)

assert(
    activation.backup
        == home
            .. "/.local/state/grimoire/"
            .. "transactions/"
            .. "hyprland.lua.bak"
)

assert(
    activation.line
        == 'require("grimoire-loader")'
)

assert(
    loader_action.operation.destination
        == activation.loader
)

assert(
    loader_action.operation.source
        == activation.loader_source
)

local dry_result =
    ActionDispatcher.dispatch(
        activation,
        {
            dry_run = true,
        }
    )

assert(dry_result.ok == true)

local result =
    assert(
        dry_result.details.hypr_activation
    )

assert(result.mode == "dry-run")
assert(result.status == "ready")
assert(result.simulated == true)
assert(result.executed == false)
assert(result.changed == false)

assert(
    result.loader_from_plan == true
        or result.loader_from_plan == false
)

if result.loader_from_plan then
    assert(
        result.loader_source
            == "config/hypr/"
                .. "grimoire-loader.lua"
    )
end

print("")
print(
    "Chargeur déployé : action "
        .. tostring(loader_sequence)
)

print(
    "Config Grimoire  : action "
        .. tostring(grimoire_sequence)
)

print(
    "Activation Hypr  : action "
        .. tostring(activation_sequence)
)

print("")
print(
    "RC4-D10A3 OK : l’activation est "
        .. "planifiée après tous ses prérequis."
)
