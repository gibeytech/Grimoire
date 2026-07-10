local SystemExecutor = require("installer.system_executor")

local FilesystemExecutor = {}

local SUPPORTED_OPERATIONS = {
    copy = true,
    symlink = true,
    mkdir = true,
}

local function shell_quote(value)
    local string_value = tostring(value)

    return "'" .. string_value:gsub("'", "'\\''") .. "'"
end

local function value_is_present(value)
    return value ~= nil and tostring(value) ~= ""
end

local function create_invalid_result(operation, error_message)
    return {
        ok = false,
        operation = operation,
        command = nil,
        executed = false,
        exit_code = nil,
        reason = nil,
        system_result = nil,
        parent_directory = nil,
        parent_result = nil,
        error = error_message,
    }
end

local function validate_source_and_destination(operation)
    if not value_is_present(operation.source) then
        return false, "Source d'opération filesystem manquante"
    end

    if not value_is_present(operation.destination) then
        return false, "Destination d'opération filesystem manquante"
    end

    return true, nil
end

local function validate_destination(operation)
    if not value_is_present(operation.destination) then
        return false, "Destination d'opération filesystem manquante"
    end

    return true, nil
end

local function validate_operation(operation)
    if type(operation) ~= "table" then
        return false, "Opération filesystem invalide"
    end

    if not value_is_present(operation.type) then
        return false, "Type d'opération filesystem manquant"
    end

    if not SUPPORTED_OPERATIONS[operation.type] then
        return false, "Type d'opération filesystem inconnu: "
            .. tostring(operation.type)
    end

    if operation.type == "copy" or operation.type == "symlink" then
        return validate_source_and_destination(operation)
    end

    if operation.type == "mkdir" then
        return validate_destination(operation)
    end

    return false, "Contrat d'opération filesystem introuvable: "
        .. tostring(operation.type)
end

local function normalize_destination(destination)
    local normalized = tostring(destination)

    while #normalized > 1 and normalized:sub(-1) == "/" do
        normalized = normalized:sub(1, -2)
    end

    return normalized
end

local function resolve_parent_directory(destination)
    local normalized = normalize_destination(destination)
    local parent = normalized:match("^(.*)/[^/]+$")

    if parent == nil then
        return "."
    end

    if parent == "" then
        return "/"
    end

    return parent
end

local function operation_requires_parent(operation)
    return operation.type == "copy"
        or operation.type == "symlink"
end

local function build_copy_command(operation)
    return table.concat({
        "cp",
        "-R",
        "--",
        shell_quote(operation.source),
        shell_quote(operation.destination),
    }, " ")
end

local function build_symlink_command(operation)
    return table.concat({
        "ln",
        "-s",
        "--",
        shell_quote(operation.source),
        shell_quote(operation.destination),
    }, " ")
end

local function build_mkdir_command(operation)
    return table.concat({
        "mkdir",
        "-p",
        "--",
        shell_quote(operation.destination),
    }, " ")
end

local function build_command(operation)
    if operation.type == "copy" then
        return build_copy_command(operation)
    end

    if operation.type == "symlink" then
        return build_symlink_command(operation)
    end

    if operation.type == "mkdir" then
        return build_mkdir_command(operation)
    end

    return nil
end

local function create_execution_result(
    operation,
    command,
    system_result,
    parent_directory,
    parent_result
)
    return {
        ok = system_result.ok,
        operation = operation,
        command = command,
        executed = system_result.executed,
        exit_code = system_result.exit_code,
        reason = system_result.reason,
        system_result = system_result,
        parent_directory = parent_directory,
        parent_result = parent_result,
        error = system_result.error,
    }
end

local function create_parent_failure_result(
    operation,
    command,
    parent_directory,
    parent_result
)
    return {
        ok = false,
        operation = operation,
        command = command,
        executed = parent_result.executed == true,
        exit_code = parent_result.exit_code,
        reason = parent_result.reason,
        system_result = parent_result.system_result,
        parent_directory = parent_directory,
        parent_result = parent_result,
        error = "Impossible de préparer le répertoire parent: "
            .. tostring(parent_result.error),
    }
end

function FilesystemExecutor.prepare(operation)
    local valid, validation_error = validate_operation(operation)

    if not valid then
        return create_invalid_result(operation, validation_error)
    end

    local command = build_command(operation)

    if not command then
        return create_invalid_result(
            operation,
            "Impossible de construire la commande filesystem"
        )
    end

    local parent_directory = nil

    if operation_requires_parent(operation) then
        parent_directory = resolve_parent_directory(
            operation.destination
        )
    end

    return {
        ok = true,
        operation = operation,
        command = command,
        executed = false,
        exit_code = nil,
        reason = nil,
        system_result = nil,
        parent_directory = parent_directory,
        parent_result = nil,
        error = nil,
    }
end

function FilesystemExecutor.execute(operation)
    local prepared_result = FilesystemExecutor.prepare(operation)

    if not prepared_result.ok then
        return prepared_result
    end

    local parent_result = nil

    if prepared_result.parent_directory then
        parent_result = FilesystemExecutor.mkdir(
            prepared_result.parent_directory
        )

        if not parent_result.ok then
            return create_parent_failure_result(
                operation,
                prepared_result.command,
                prepared_result.parent_directory,
                parent_result
            )
        end
    end

    local system_result = SystemExecutor.execute(
        prepared_result.command
    )

    return create_execution_result(
        operation,
        prepared_result.command,
        system_result,
        prepared_result.parent_directory,
        parent_result
    )
end

function FilesystemExecutor.copy(source, destination)
    return FilesystemExecutor.execute({
        type = "copy",
        source = source,
        destination = destination,
    })
end

function FilesystemExecutor.symlink(source, destination)
    return FilesystemExecutor.execute({
        type = "symlink",
        source = source,
        destination = destination,
    })
end

function FilesystemExecutor.mkdir(destination)
    return FilesystemExecutor.execute({
        type = "mkdir",
        destination = destination,
    })
end

return FilesystemExecutor
