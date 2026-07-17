package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local FilesystemPreflight = require(
    "installer.filesystem_preflight"
)

print(
    "== FilesystemPreflight "
        .. "RC4-D8 Contract Test =="
)

local function shell_quote(value)
    return "'"
        .. tostring(value):gsub(
            "'",
            "'\\''"
        )
        .. "'"
end

local function command_succeeded(command)
    local ok, _, code = os.execute(command)

    return ok == true
        or ok == 0
        or code == 0
end

local function write_file(path, content)
    local file = assert(
        io.open(path, "wb")
    )

    assert(file:write(content))
    assert(file:close())
end

local function copy_directory(
    source,
    destination
)
    assert(
        command_succeeded(
            "cp -R -- "
                .. shell_quote(source)
                .. " "
                .. shell_quote(destination)
        )
    )
end

local temporary_directory =
    os.tmpname()

os.remove(temporary_directory)

temporary_directory =
    temporary_directory
        .. " préflight d'utilisateur"

assert(
    command_succeeded(
        "mkdir -p -- "
            .. shell_quote(
                temporary_directory
            )
    )
)

local test_ok, test_error =
    xpcall(
        function()
            local source =
                temporary_directory
                    .. "/source d'utilisateur"

            local nested =
                source .. "/nested"

            assert(
                command_succeeded(
                    "mkdir -p -- "
                        .. shell_quote(nested)
                )
            )

            write_file(
                nested .. "/contenu.txt",
                "contenu Grimoire\n"
            )

            local missing_source =
                FilesystemPreflight.inspect({
                    type = "file_operation",
                    manager = "deploy",
                    name = "missing-source",
                    operation = {
                        type = "copy",
                        source =
                            temporary_directory
                                .. "/source absente",
                        destination =
                            temporary_directory
                                .. "/destination absente",
                        overwrite = false,
                    },
                })

            assert(missing_source.ok == false)
            assert(
                missing_source.status
                    == "invalid-source"
            )
            assert(missing_source.blocking == true)

            local ready_destination =
                temporary_directory
                    .. "/destination prête"

            local ready =
                FilesystemPreflight.inspect({
                    type = "file_operation",
                    manager = "deploy",
                    name = "ready-create",
                    operation = {
                        type = "copy",
                        source = source,
                        destination =
                            ready_destination,
                        overwrite = false,
                    },
                })

            assert(ready.ok == true)
            assert(
                ready.status == "ready-create"
            )
            assert(ready.ready == true)
            assert(ready.blocking == false)

            local identical_destination =
                temporary_directory
                    .. "/destination identique"

            copy_directory(
                source,
                identical_destination
            )

            local identical =
                FilesystemPreflight.inspect({
                    type = "file_operation",
                    manager = "deploy",
                    name = "identical",
                    operation = {
                        type = "copy",
                        source = source,
                        destination =
                            identical_destination,
                        overwrite = false,
                    },
                })

            assert(identical.ok == true)

            assert(
                identical.status
                    == "already-satisfied"
            )

            local empty_destination =
                temporary_directory
                    .. "/destination vide"

            assert(
                command_succeeded(
                    "mkdir -p -- "
                        .. shell_quote(
                            empty_destination
                        )
                )
            )

            local empty =
                FilesystemPreflight.inspect({
                    type = "file_operation",
                    manager = "deploy",
                    name = "empty",
                    operation = {
                        type = "copy",
                        source = source,
                        destination =
                            empty_destination,
                        overwrite = false,
                    },
                })

            assert(empty.ok == false)

            assert(
                empty.status
                    == "conflict-empty"
            )

            local conflict_destination =
                temporary_directory
                    .. "/destination conflit"

            copy_directory(
                source,
                conflict_destination
            )

            write_file(
                conflict_destination
                    .. "/nested/contenu.txt",
                "contenu divergent\n"
            )

            local conflict =
                FilesystemPreflight.inspect({
                    type = "file_operation",
                    manager = "deploy",
                    name = "conflict",
                    operation = {
                        type = "copy",
                        source = source,
                        destination =
                            conflict_destination,
                        overwrite = false,
                    },
                })

            assert(conflict.ok == false)
            assert(conflict.status == "conflict")
            assert(conflict.blocking == true)

            local unsafe =
                FilesystemPreflight.inspect({
                    type = "file_operation",
                    manager = "deploy",
                    name = "unsafe-overwrite",
                    operation = {
                        type = "copy",
                        source = source,
                        destination =
                            conflict_destination,
                        overwrite = true,
                    },
                })

            assert(unsafe.ok == false)

            assert(
                unsafe.status
                    == "unsafe-overwrite"
            )
        end,
        debug.traceback
    )

assert(
    command_succeeded(
        "rm -rf -- "
            .. shell_quote(
                temporary_directory
            )
    )
)

if not test_ok then
    error(test_error)
end

print("")
print(
    "RC4-D8 OK : le préflight classe "
        .. "les créations, identités et conflits."
)
