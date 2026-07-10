package.path = "./?.lua;./?/init.lua;" .. package.path

local Builder = require("installer.builder")
local ExecutionPlanBuilder = require(
    "installer.execution_plan_builder"
)

print("== ExecutionPlanBuilder RC2-D2 Path Resolver Test ==")

local test_home = "/home/grimoire-test"

local installation_plan = Builder.build("gibeytech")

local execution_plan = ExecutionPlanBuilder.build(
    installation_plan,
    {
        dry_run = true,
        home = test_home,
    }
)

local function find_action(manager, name)
    for _, action in ipairs(execution_plan:getActions()) do
        if action.manager == manager and action.name == name then
            return action
        end
    end

    return nil
end

----------------------------------------------------------------------
-- Wallpapers
----------------------------------------------------------------------

local wallpapers_action = find_action(
    "assets",
    "wallpapers"
)

assert(wallpapers_action ~= nil)
assert(wallpapers_action.type == "file_operation")
assert(wallpapers_action.operation.type == "copy")
assert(
    wallpapers_action.operation.source
        == "profiles/gibeytech/wallpapers"
)
assert(
    wallpapers_action.operation.destination
        == "/home/grimoire-test/.local/share/grimoire/wallpapers"
)
assert(wallpapers_action.operation.overwrite == nil)

----------------------------------------------------------------------
-- Themes
----------------------------------------------------------------------

local themes_action = find_action(
    "assets",
    "themes"
)

assert(themes_action ~= nil)
assert(themes_action.type == "file_operation")
assert(themes_action.operation.type == "copy")
assert(
    themes_action.operation.source
        == "profiles/gibeytech/themes"
)
assert(
    themes_action.operation.destination
        == "/home/grimoire-test/.local/share/themes"
)

----------------------------------------------------------------------
-- Icons
----------------------------------------------------------------------

local icons_action = find_action(
    "assets",
    "icons"
)

assert(icons_action ~= nil)
assert(icons_action.type == "file_operation")
assert(icons_action.operation.type == "copy")
assert(
    icons_action.operation.source
        == "profiles/gibeytech/icons"
)
assert(
    icons_action.operation.destination
        == "/home/grimoire-test/.local/share/icons"
)

----------------------------------------------------------------------
-- Dotfiles
----------------------------------------------------------------------

local dotfiles_action = find_action(
    "deploy",
    "dotfiles"
)

assert(dotfiles_action ~= nil)
assert(dotfiles_action.type == "file_operation")
assert(dotfiles_action.operation.type == "symlink")
assert(
    dotfiles_action.operation.source
        == "profiles/gibeytech/dotfiles"
)
assert(
    dotfiles_action.operation.destination
        == "/home/grimoire-test/.config"
)
assert(dotfiles_action.operation.overwrite == nil)

----------------------------------------------------------------------
-- Aucun chemin utilisateur non résolu
----------------------------------------------------------------------

for _, action in ipairs(execution_plan:getActions()) do
    if action.type == "file_operation" then
        local operation = action.operation

        assert(type(operation.source) == "string")
        assert(type(operation.destination) == "string")

        assert(operation.source:find("~", 1, true) == nil)
        assert(operation.destination:find("~", 1, true) == nil)

        assert(operation.source:find("$HOME", 1, true) == nil)
        assert(
            operation.destination:find(
                "$HOME",
                1,
                true
            ) == nil
        )

        assert(
            operation.source:find(
                "${HOME}",
                1,
                true
            ) == nil
        )

        assert(
            operation.destination:find(
                "${HOME}",
                1,
                true
            ) == nil
        )
    end
end

----------------------------------------------------------------------
-- Mode apply-real transmis
----------------------------------------------------------------------

local apply_real_plan = ExecutionPlanBuilder.build(
    installation_plan,
    {
        dry_run = false,
        apply_real = true,
        home = test_home,
    }
)

assert(apply_real_plan.mode == "apply-real")

print("")
print("RC2-D2 OK : l'ExecutionPlan contient des chemins résolus.")
