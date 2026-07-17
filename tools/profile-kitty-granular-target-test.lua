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
    "== Profile RC4-D9A "
        .. "Kitty Granular Target Test =="
)

local home =
    os.getenv("HOME")

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

local kitty_action = nil
local kitty_sequence = nil

for sequence, action in ipairs(
    execution_plan:getActions()
) do
    if action.type == "file_operation"
        and action.manager == "deploy"
        and action.name == "kitty"
    then
        kitty_action = action
        kitty_sequence = sequence
        break
    end
end

assert(
    type(kitty_action) == "table",
    "Action deploy/kitty absente"
)

assert(kitty_sequence == 12)

local operation =
    assert(kitty_action.operation)

assert(operation.type == "copy")

assert(
    operation.source
        == "config/kitty/kitty.conf"
)

assert(
    operation.destination
        == home
            .. "/.config/kitty/kitty.conf"
)

assert(operation.overwrite == false)

local source_file =
    assert(io.open(operation.source, "rb"))

source_file:close()

local preflight =
    FilesystemPreflight.inspect(
        kitty_action,
        {
            dry_run = false,
            apply_real = true,
        },
        kitty_sequence
    )

assert(preflight.ok == true)

assert(
    preflight.status == "ready-create",
    "Statut Kitty inattendu : "
        .. tostring(preflight.status)
)

assert(preflight.blocking == false)
assert(preflight.ready == true)

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
    "RC4-D9A OK : Kitty cible uniquement "
        .. "le fichier kitty.conf."
)
