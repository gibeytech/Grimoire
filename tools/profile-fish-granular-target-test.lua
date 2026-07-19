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
    "== Profile RC4-D9B "
        .. "Fish Granular Target Test =="
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

local fish_action = nil
local fish_sequence = nil

for sequence, action in ipairs(
    execution_plan:getActions()
) do
    if action.type == "file_operation" then
        local operation =
            action.operation or {}

        assert(
            operation.destination
                ~= home .. "/.config/fish",
            "Le répertoire Fish complet "
                .. "ne doit pas être ciblé"
        )

        assert(
            operation.destination
                ~= home
                    .. "/.config/fish/fish_variables",
            "fish_variables ne doit jamais "
                .. "être géré par le profil"
        )
    end

    if action.type == "file_operation"
        and action.manager == "deploy"
        and action.name == "fish"
    then
        fish_action = action
        fish_sequence = sequence
    end
end

assert(
    type(fish_action) == "table",
    "Action deploy/fish absente"
)

assert(fish_sequence == 15)

local operation =
    assert(fish_action.operation)

assert(operation.type == "copy")

assert(
    operation.source
        == "config/fish/config.fish"
)

assert(
    operation.destination
        == home
            .. "/.config/fish/config.fish"
)

assert(operation.overwrite == false)

local source_file =
    assert(io.open(operation.source, "rb"))

source_file:close()

local preflight =
    FilesystemPreflight.inspect(
        fish_action,
        {
            dry_run = false,
            apply_real = true,
        },
        fish_sequence
    )

assert(type(preflight.status) == "string")

assert(
    preflight.status == "ready-create"
        or preflight.status
            == "already-satisfied"
        or preflight.status == "conflict",
    "Classification Fish inattendue : "
        .. tostring(preflight.status)
)

assert(
    preflight.status ~= "conflict-empty"
)

print("")
print(
    "Source      : "
        .. tostring(operation.source)
)

print(
    "Destination : "
        .. tostring(operation.destination)
)

print(
    "Préflight   : "
        .. tostring(preflight.status)
)

print("")
print(
    "RC4-D9B OK : Fish cible uniquement "
        .. "config.fish et préserve fish_variables."
)
