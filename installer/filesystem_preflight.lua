local SystemExecutor = require(
    "installer.system_executor"
)

local FilesystemPreflight = {}

local SUPPORTED_OPERATIONS = {
    copy = true,
    symlink = true,
    mkdir = true,
}

local BLOCKING_STATUSES = {
    ["invalid-operation"] = true,
    ["invalid-source"] = true,
    ["unsafe-overwrite"] = true,
    ["conflict-empty"] = true,
    conflict = true,
}

local function value_is_present(value)
    return value ~= nil
        and tostring(value) ~= ""
end

local function shell_quote(value)
    return "'"
        .. tostring(value):gsub(
            "'",
            "'\\''"
        )
        .. "'"
end

local function trim(value)
    if value == nil then
        return ""
    end

    return tostring(value):match(
        "^%s*(.-)%s*$"
    ) or ""
end

local function execution_options(options)
    options = options or {}

    return {
        timeout_seconds =
            options.timeout_seconds,
        kill_after_seconds =
            options.kill_after_seconds,
    }
end

local function run(command, options)
    return SystemExecutor.execute(
        command,
        execution_options(options)
    )
end

local function command_succeeded(
    command,
    options
)
    local result = run(command, options)

    return result.ok == true, result
end

local function path_exists(path, options)
    return command_succeeded(
        "test -e "
            .. shell_quote(path)
            .. " || test -L "
            .. shell_quote(path),
        options
    )
end

local function path_is_directory(
    path,
    options
)
    return command_succeeded(
        "test -d " .. shell_quote(path),
        options
    )
end

local function path_is_symlink(
    path,
    options
)
    return command_succeeded(
        "test -L " .. shell_quote(path),
        options
    )
end

local function directory_is_empty(
    path,
    options
)
    return command_succeeded(
        "test -d "
            .. shell_quote(path)
            .. " && [ -z \"$(find "
            .. shell_quote(path)
            .. " -mindepth 1 "
            .. "-print -quit 2>/dev/null)\" ]",
        options
    )
end

local function paths_are_identical(
    source,
    destination,
    options
)
    return command_succeeded(
        "diff -qr -- "
            .. shell_quote(source)
            .. " "
            .. shell_quote(destination)
            .. " >/dev/null 2>&1",
        options
    )
end

local function symlink_matches(
    source,
    destination,
    options
)
    local destination_is_link =
        path_is_symlink(
            destination,
            options
        )

    if not destination_is_link then
        return false
    end

    local result = run(
        "readlink -- "
            .. shell_quote(destination),
        options
    )

    if not result.ok then
        return false
    end

    return trim(result.stdout)
        == tostring(source)
end

local function create_entry(
    action,
    sequence
)
    local operation =
        type(action) == "table"
        and action.operation
        or nil

    return {
        ok = false,
        ready = false,
        blocking = true,
        sequence = sequence or 0,
        type = action
            and action.type
            or nil,
        manager = action
            and action.manager
            or "unknown",
        name = action
            and action.name
            or "unknown",
        action = action,
        operation = operation,
        operation_type = operation
            and operation.type
            or nil,
        source = operation
            and operation.source
            or nil,
        destination = operation
            and operation.destination
            or nil,
        overwrite = operation
            and operation.overwrite == true
            or false,
        status = "invalid-operation",
        reason = nil,
        error = nil,
    }
end

local function finalize(
    entry,
    status,
    reason
)
    entry.status = status
    entry.reason = reason

    entry.blocking =
        BLOCKING_STATUSES[status] == true

    entry.ready =
        not entry.blocking

    entry.ok =
        not entry.blocking

    if entry.blocking then
        entry.error = reason
    else
        entry.error = nil
    end

    return entry
end

local function validate_operation(entry)
    local operation = entry.operation

    if type(operation) ~= "table" then
        return false,
            "Opération filesystem absente"
    end

    if not value_is_present(operation.type) then
        return false,
            "Type d'opération filesystem manquant"
    end

    if not SUPPORTED_OPERATIONS[
        operation.type
    ] then
        return false,
            "Type d'opération filesystem inconnu : "
                .. tostring(operation.type)
    end

    if not value_is_present(
        operation.destination
    ) then
        return false,
            "Destination filesystem manquante"
    end

    if operation.overwrite == true then
        return false,
            "overwrite=true est interdit "
                .. "sans sauvegarde préalable"
    end

    if operation.type == "copy"
        or operation.type == "symlink"
    then
        if not value_is_present(
            operation.source
        ) then
            return false,
                "Source filesystem manquante"
        end
    end

    return true, nil
end

function FilesystemPreflight.inspect(
    action,
    options,
    sequence
)
    options = options or {}

    local entry = create_entry(
        action,
        sequence
    )

    local valid, validation_error =
        validate_operation(entry)

    if not valid then
        local status =
            entry.operation
            and entry.operation.overwrite == true
            and "unsafe-overwrite"
            or "invalid-operation"

        return finalize(
            entry,
            status,
            validation_error
        )
    end

    local operation = entry.operation
    local source = operation.source
    local destination =
        operation.destination

    if operation.type == "copy"
        or operation.type == "symlink"
    then
        local source_exists =
            path_exists(source, options)

        if not source_exists then
            return finalize(
                entry,
                "invalid-source",
                "Source filesystem introuvable : "
                    .. tostring(source)
            )
        end
    end

    local destination_exists =
        path_exists(
            destination,
            options
        )

    if not destination_exists then
        return finalize(
            entry,
            "ready-create",
            "La destination sera créée"
        )
    end

    if operation.type == "mkdir" then
        local destination_is_directory =
            path_is_directory(
                destination,
                options
            )

        if destination_is_directory then
            return finalize(
                entry,
                "already-satisfied",
                "Le répertoire existe déjà"
            )
        end

        return finalize(
            entry,
            "conflict",
            "La destination mkdir existe "
                .. "mais n'est pas un répertoire"
        )
    end

    if operation.type == "symlink"
        and symlink_matches(
            source,
            destination,
            options
        )
    then
        return finalize(
            entry,
            "already-satisfied",
            "Le lien symbolique cible déjà "
                .. "la source attendue"
        )
    end

    if operation.type == "copy"
        and paths_are_identical(
            source,
            destination,
            options
        )
    then
        return finalize(
            entry,
            "already-satisfied",
            "La destination est strictement "
                .. "identique à la source"
        )
    end

    local empty_destination =
        directory_is_empty(
            destination,
            options
        )

    if empty_destination then
        return finalize(
            entry,
            "conflict-empty",
            "La destination existe mais est vide"
        )
    end

    return finalize(
        entry,
        "conflict",
        "La destination existe et diffère "
            .. "de la source"
    )
end

local function create_counts()
    return {
        ready_create = 0,
        already_satisfied = 0,
        conflict_empty = 0,
        conflict = 0,
        invalid_source = 0,
        invalid_operation = 0,
        unsafe_overwrite = 0,
        blocking = 0,
    }
end

local function increment_count(
    counts,
    status
)
    local key =
        tostring(status):gsub("-", "_")

    if counts[key] ~= nil then
        counts[key] = counts[key] + 1
    end

    if BLOCKING_STATUSES[status] then
        counts.blocking =
            counts.blocking + 1
    end
end

local function build_error(entries)
    local blocked = {}

    for _, entry in ipairs(entries) do
        if entry.blocking then
            table.insert(
                blocked,
                tostring(entry.manager)
                    .. "/"
                    .. tostring(entry.name)
                    .. " : "
                    .. tostring(entry.status)
            )
        end
    end

    if #blocked == 0 then
        return nil
    end

    return "Préflight filesystem refusé : "
        .. table.concat(blocked, "; ")
end

function FilesystemPreflight.not_required(mode)
    return {
        ok = true,
        status = "not-required",
        mode = mode or "dry-run",
        inspected = false,
        total = 0,
        file_operations = 0,
        entries = {},
        by_sequence = {},
        counts = create_counts(),
        error = nil,
    }
end

function FilesystemPreflight.run(
    execution_plan,
    options
)
    options = options or {}

    local result = {
        ok = true,
        status = "ready",
        mode = options.apply_real == true
            and "apply-real"
            or "inspection",
        inspected = true,
        total = 0,
        file_operations = 0,
        entries = {},
        by_sequence = {},
        counts = create_counts(),
        error = nil,
    }

    if not execution_plan
        or type(
            execution_plan.getActions
        ) ~= "function"
    then
        result.ok = false
        result.status = "invalid"
        result.error =
            "FilesystemPreflight attend "
                .. "un ExecutionPlan"

        return result
    end

    local actions =
        execution_plan:getActions() or {}

    result.total = #actions

    for sequence, action in ipairs(actions) do
        if action.type == "file_operation" then
            local entry =
                FilesystemPreflight.inspect(
                    action,
                    options,
                    sequence
                )

            result.file_operations =
                result.file_operations + 1

            table.insert(
                result.entries,
                entry
            )

            result.by_sequence[sequence] =
                entry

            increment_count(
                result.counts,
                entry.status
            )
        end
    end

    if result.counts.blocking > 0 then
        result.ok = false
        result.status = "blocked"
        result.error =
            build_error(result.entries)

        return result
    end

    result.status = "ready"
    result.error = nil

    return result
end

return FilesystemPreflight
