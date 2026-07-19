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
    "== ExecutionPlanBuilder RC4-D9C "
        .. "Path Resolver Test =="
)

local home = os.getenv("HOME")

assert(type(home) == "string")
assert(home ~= "")

local execution_plan =
    ExecutionPlanBuilder.build(
        Builder.build("gibeytech"),
        {
            dry_run = true,
        }
    )

local expected = {
    ["assets/gtk-theme"] = {
        source =
            "profiles/gibeytech/assets/themes/Grimoire",
        destination =
            home
                .. "/.local/share/themes/Grimoire",
    },

    ["assets/cursor-theme"] = {
        source =
            "profiles/gibeytech/assets/icons/"
                .. "Grimoire-Cursors",
        destination =
            home
                .. "/.local/share/icons/"
                .. "Grimoire-Cursors",
    },

    ["deploy/hypr-grimoire-loader"] = {
        source =
            "config/hypr/grimoire-loader.lua",
        destination =
            home
                .. "/.config/hypr/"
                .. "grimoire-loader.lua",
    },

    ["deploy/hypridle"] = {
        source =
            "config/hypr/hypridle.conf",
        destination =
            home
                .. "/.config/hypr/"
                .. "hypridle.conf",
    },

    ["deploy/hyprlock"] = {
        source =
            "config/hypr/hyprlock.conf",
        destination =
            home
                .. "/.config/hypr/"
                .. "hyprlock.conf",
    },

    ["deploy/kitty"] = {
        source =
            "config/kitty/kitty.conf",
        destination =
            home
                .. "/.config/kitty/kitty.conf",
    },

    ["deploy/fish"] = {
        source =
            "config/fish/config.fish",
        destination =
            home
                .. "/.config/fish/config.fish",
    },

    ["deploy/swaync"] = {
        source = "config/swaync",
        destination =
            home .. "/.config/swaync",
    },

    ["deploy/wlogout"] = {
        source = "config/wlogout",
        destination =
            home .. "/.config/wlogout",
    },

    ["deploy/grimoire"] = {
        source = "config/grimoire",
        destination =
            home .. "/.config/grimoire",
    },
}

local filesystem_count = 0
local seen = {}

for _, action in ipairs(
    execution_plan:getActions()
) do
    if action.type == "file_operation" then
        filesystem_count =
            filesystem_count + 1

        local key =
            tostring(action.manager)
                .. "/"
                .. tostring(action.name)

        local expected_operation =
            expected[key]

        assert(
            type(expected_operation)
                == "table",
            "Action filesystem inattendue : "
                .. key
        )

        local operation =
            assert(action.operation)

        assert(
            operation.source
                == expected_operation.source,
            "Source inattendue pour " .. key
        )

        assert(
            operation.destination
                == expected_operation.destination,
            "Destination inattendue pour "
                .. key
        )

        assert(operation.type == "copy")
        assert(operation.overwrite == false)

        assert(
            operation.destination
                ~= home .. "/.config",
            "Le répertoire ~/.config complet "
                .. "ne doit jamais être ciblé"
        )

        assert(
            operation.destination
                ~= home .. "/.config/hypr",
            "Le répertoire Hypr complet "
                .. "ne doit jamais être ciblé"
        )

        assert(
            operation.destination
                ~= home
                    .. "/.config/hypr/"
                    .. "hyprland.lua",
            "hyprland.lua actif ne doit "
                .. "jamais être ciblé"
        )

        seen[key] = true
    end
end

assert(filesystem_count == 10)

for key in pairs(expected) do
    assert(
        seen[key] == true,
        "Action absente : " .. key
    )
end

print("")
print(
    "Actions filesystem : "
        .. tostring(filesystem_count)
)

print("")
print(
    "RC4-D9C OK : le plan utilise dix "
        .. "destinations explicites et sûres."
)
