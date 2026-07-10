package.path = "./?.lua;./?/init.lua;" .. package.path

local FilesystemExecutor = require("installer.filesystem_executor")

print("== FilesystemExecutor RC2-C5 Overwrite Policy Test ==")

----------------------------------------------------------------------
-- Copy sans overwrite explicite
----------------------------------------------------------------------

local copy_default_result = FilesystemExecutor.prepare({
    type = "copy",
    source = "source.txt",
    destination = "destination.txt",
})

assert(copy_default_result.ok == true)
assert(copy_default_result.overwrite == false)
assert(type(copy_default_result.command) == "string")
assert(
    copy_default_result.command:find(
        "Destination filesystem existante",
        1,
        true
    ) ~= nil
)
assert(
    copy_default_result.command:find(
        "cp -R --",
        1,
        true
    ) ~= nil
)
assert(
    copy_default_result.command:find(
        "cp -R -f --",
        1,
        true
    ) == nil
)

----------------------------------------------------------------------
-- Copy avec overwrite = false
----------------------------------------------------------------------

local copy_false_result = FilesystemExecutor.prepare({
    type = "copy",
    source = "source.txt",
    destination = "destination.txt",
    overwrite = false,
})

assert(copy_false_result.ok == true)
assert(copy_false_result.overwrite == false)
assert(
    copy_false_result.command:find(
        "Destination filesystem existante",
        1,
        true
    ) ~= nil
)
assert(
    copy_false_result.command:find(
        "cp -R --",
        1,
        true
    ) ~= nil
)

----------------------------------------------------------------------
-- Copy avec overwrite = true
----------------------------------------------------------------------

local copy_true_result = FilesystemExecutor.prepare({
    type = "copy",
    source = "source.txt",
    destination = "destination.txt",
    overwrite = true,
})

assert(copy_true_result.ok == true)
assert(copy_true_result.overwrite == true)
assert(
    copy_true_result.command:find(
        "Destination filesystem existante",
        1,
        true
    ) == nil
)
assert(
    copy_true_result.command:find(
        "cp -R -f --",
        1,
        true
    ) ~= nil
)

----------------------------------------------------------------------
-- Symlink sans overwrite explicite
----------------------------------------------------------------------

local symlink_default_result = FilesystemExecutor.prepare({
    type = "symlink",
    source = "source.txt",
    destination = "link.txt",
})

assert(symlink_default_result.ok == true)
assert(symlink_default_result.overwrite == false)
assert(
    symlink_default_result.command:find(
        "Destination filesystem existante",
        1,
        true
    ) ~= nil
)
assert(
    symlink_default_result.command:find(
        "ln -s --",
        1,
        true
    ) ~= nil
)
assert(
    symlink_default_result.command:find(
        "ln -s -f -n -T --",
        1,
        true
    ) == nil
)

----------------------------------------------------------------------
-- Symlink avec overwrite = false
----------------------------------------------------------------------

local symlink_false_result = FilesystemExecutor.prepare({
    type = "symlink",
    source = "source.txt",
    destination = "link.txt",
    overwrite = false,
})

assert(symlink_false_result.ok == true)
assert(symlink_false_result.overwrite == false)
assert(
    symlink_false_result.command:find(
        "Destination filesystem existante",
        1,
        true
    ) ~= nil
)
assert(
    symlink_false_result.command:find(
        "ln -s --",
        1,
        true
    ) ~= nil
)

----------------------------------------------------------------------
-- Symlink avec overwrite = true
----------------------------------------------------------------------

local symlink_true_result = FilesystemExecutor.prepare({
    type = "symlink",
    source = "source.txt",
    destination = "link.txt",
    overwrite = true,
})

assert(symlink_true_result.ok == true)
assert(symlink_true_result.overwrite == true)
assert(
    symlink_true_result.command:find(
        "Destination filesystem existante",
        1,
        true
    ) == nil
)
assert(
    symlink_true_result.command:find(
        "ln -s -f -n -T --",
        1,
        true
    ) ~= nil
)

----------------------------------------------------------------------
-- Overwrite invalide
----------------------------------------------------------------------

local invalid_overwrite_result = FilesystemExecutor.prepare({
    type = "copy",
    source = "source.txt",
    destination = "destination.txt",
    overwrite = "true",
})

assert(invalid_overwrite_result.ok == false)
assert(invalid_overwrite_result.command == nil)
assert(invalid_overwrite_result.executed == false)
assert(invalid_overwrite_result.overwrite == false)
assert(
    invalid_overwrite_result.error
        == "La politique overwrite doit être un booléen"
)

----------------------------------------------------------------------
-- mkdir reste indépendant de la politique
----------------------------------------------------------------------

local mkdir_result = FilesystemExecutor.prepare({
    type = "mkdir",
    destination = "directory",
})

assert(mkdir_result.ok == true)
assert(mkdir_result.overwrite == false)
assert(mkdir_result.command == "mkdir -p -- 'directory'")

print("")
print("RC2-C5 OK : la politique overwrite est explicite et validée.")
