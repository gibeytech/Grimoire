package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local Builder = require(
    "installer.builder"
)

local ExecutionPlanBuilder = require(
    "installer.execution_plan_builder"
)

print(
    "== ExecutionPlanBuilder "
        .. "RC4-D6 Path Resolver Test =="
)

local test_home =
    "/home/grimoire-test"

local installation_plan =
    Builder.build("gibeytech")

local execution_plan =
    ExecutionPlanBuilder.build(
        installation_plan,
        {
            dry_run = true,
            home = test_home,
        }
    )

local function find_action(manager, name)
    for _, action in ipairs(
        execution_plan:getActions()
    ) do
        if action.manager == manager
            and action.name == name
        then
            return action
        end
    end

    return nil
end

local function assert_operation(
    manager,
    name,
    operation_type,
    source,
    destination
)
    local action =
        find_action(manager, name)

    assert(
        action ~= nil,
        "Action absente : "
            .. manager
            .. "/"
            .. name
    )

    assert(action.type == "file_operation")
    assert(action.operation.type == operation_type)
    assert(action.operation.source == source)
    assert(
        action.operation.destination
            == destination
    )

    assert(
        action.operation.overwrite
            == false
    )
end

assert_operation(
    "assets",
    "gtk-theme",
    "copy",
    "profiles/gibeytech/assets/themes/Grimoire",
    test_home
        .. "/.local/share/themes/Grimoire"
)

assert_operation(
    "assets",
    "cursor-theme",
    "copy",
    "profiles/gibeytech/assets/icons/Grimoire-Cursors",
    test_home
        .. "/.local/share/icons/Grimoire-Cursors"
)

local dotfiles = {
    {
        name = "hypr",
        source = "config/hypr",
        destination =
            test_home .. "/.config/hypr",
    },
    {
        name = "kitty",
        source = "config/kitty/kitty.conf",
        destination =
            test_home
                .. "/.config/kitty/kitty.conf",
    },
    {
        name = "fish",
        source = "config/fish/config.fish",
        destination =
            test_home
                .. "/.config/fish/config.fish",
    },
    {
        name = "swaync",
        source = "config/swaync",
        destination =
            test_home .. "/.config/swaync",
    },
    {
        name = "wlogout",
        source = "config/wlogout",
        destination =
            test_home .. "/.config/wlogout",
    },
    {
        name = "grimoire",
        source = "config/grimoire",
        destination =
            test_home .. "/.config/grimoire",
    },
}

for _, definition in ipairs(dotfiles) do
    assert_operation(
        "deploy",
        definition.name,
        "copy",
        definition.source,
        definition.destination
    )
end

local filesystem_count = 0

for _, action in ipairs(
    execution_plan:getActions()
) do
    if action.type == "file_operation" then
        filesystem_count =
            filesystem_count + 1

        local operation = action.operation

        assert(type(operation.source) == "string")
        assert(
            type(operation.destination)
                == "string"
        )

        assert(
            operation.source:find(
                "~",
                1,
                true
            ) == nil
        )

        assert(
            operation.destination:find(
                "~",
                1,
                true
            ) == nil
        )

        assert(
            operation.source:find(
                "$HOME",
                1,
                true
            ) == nil
        )

        assert(
            operation.destination:find(
                "$HOME",
                1,
                true
            ) == nil
        )

        assert(
            operation.destination
                ~= test_home .. "/.config"
        )

        assert(
            operation.destination
                ~= test_home
                    .. "/.local/share/themes"
        )

        assert(
            operation.destination
                ~= test_home
                    .. "/.local/share/icons"
        )
    end
end

assert(filesystem_count == 8)

local apply_real_plan =
    ExecutionPlanBuilder.build(
        installation_plan,
        {
            dry_run = false,
            apply_real = true,
            home = test_home,
        }
    )

assert(
    apply_real_plan:getMode()
        == "apply-real"
)

print("")
print(
    "Actions filesystem : "
        .. tostring(filesystem_count)
)

print("")
print(
    "RC4-D6 OK : le plan utilise huit "
        .. "destinations explicites et sûres."
)
