package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local Builder = require(
    "installer.builder"
)

local ExecutionPlanBuilder = require(
    "installer.execution_plan_builder"
)

local FilesystemPreflight = require(
    "installer.filesystem_preflight"
)

print(
    "== Profile RC4-D9C "
        .. "Hypr Granular Target Test =="
)

local home = os.getenv("HOME")

assert(type(home) == "string")
assert(home ~= "")

local execution_plan =
    ExecutionPlanBuilder.build(
        Builder.build("gibeytech"),
        {
            dry_run = false,
            apply_real = true,
        }
    )

local expected = {
    ["hypr-grimoire-loader"] = {
        sequence = 11,
        source =
            "config/hypr/grimoire-loader.lua",
        destination =
            home
                .. "/.config/hypr/"
                .. "grimoire-loader.lua",
    },

    hypridle = {
        sequence = 12,
        source =
            "config/hypr/hypridle.conf",
        destination =
            home
                .. "/.config/hypr/"
                .. "hypridle.conf",
    },

    hyprlock = {
        sequence = 13,
        source =
            "config/hypr/hyprlock.conf",
        destination =
            home
                .. "/.config/hypr/"
                .. "hyprlock.conf",
    },
}

local found = {}

for sequence, action in ipairs(
    execution_plan:getActions()
) do
    if action.type == "file_operation" then
        local operation =
            assert(action.operation)

        assert(
            operation.destination
                ~= home .. "/.config/hypr",
            "Le répertoire Hypr complet "
                .. "ne doit pas être ciblé"
        )

        assert(
            operation.destination
                ~= home
                    .. "/.config/hypr/"
                    .. "hyprland.lua",
            "hyprland.lua actif ne doit "
                .. "pas être ciblé"
        )

        assert(
            operation.destination
                ~= home
                    .. "/.config/hypr/"
                    .. "hyprland.conf",
            "Le stub hyprland.conf ne doit "
                .. "pas être déployé"
        )
    end

    if action.type == "file_operation"
        and action.manager == "deploy"
        and expected[action.name]
    then
        local contract =
            expected[action.name]

        local operation =
            assert(action.operation)

        assert(sequence == contract.sequence)
        assert(operation.type == "copy")
        assert(operation.source == contract.source)

        assert(
            operation.destination
                == contract.destination
        )

        assert(operation.overwrite == false)

        local source_file =
            assert(
                io.open(
                    operation.source,
                    "rb"
                )
            )

        source_file:close()

        local inspection =
            FilesystemPreflight.inspect(
                action,
                {
                    dry_run = false,
                    apply_real = true,
                },
                sequence
            )

        assert(inspection.ok == true)

        assert(
            inspection.status
                == "ready-create",
            "Classification inattendue pour "
                .. action.name
                .. " : "
                .. tostring(
                    inspection.status
                )
        )

        found[action.name] = true
    end
end

for name in pairs(expected) do
    assert(
        found[name] == true,
        "Action Hypr absente : " .. name
    )
end

local obsolete_sources = {
    "config/hypr/hyprland.lua",
    "config/hypr/hyprland.conf",
}

for _, path in ipairs(obsolete_sources) do
    local file = io.open(path, "rb")

    assert(
        file == nil,
        "Source Hypr obsolète encore présente : "
            .. path
    )

    if file then
        file:close()
    end
end

print("")
print(
    "Chargeur : "
        .. expected[
            "hypr-grimoire-loader"
        ].destination
)

print(
    "Hypridle : "
        .. expected.hypridle.destination
)

print(
    "Hyprlock : "
        .. expected.hyprlock.destination
)

print("")
print(
    "RC4-D9C OK : Hypr cible trois "
        .. "fichiers absents sans toucher "
        .. "à hyprland.lua."
)
