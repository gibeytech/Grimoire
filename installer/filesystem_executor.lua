local SystemExecutor = require("installer.system_executor")

local FilesystemExecutor = {}

local SUPPORTED_OPERATIONS = {
    copy = true,
    symlink = true,
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
        error = error_message,
    }
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

    if not value_is_present(operation.source) then
        return false, "Source d'opération filesystem manquante"
    end

    if not value_is_present(operation.destination) then
        return false, "Destination d'opération filesystem manquante"
    end

    return true, nil
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

local function build_command(operation)
    if operation.type == "copy" then
        return build_copy_command(operation)
    end

    if operation.type == "symlink" then
        return build_symlink_command(operation)
    end

    return nil
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

    return {
        ok = true,
        operation = operation,
        command = command,
        executed = false,
        exit_code = nil,
        reason = nil,
        system_result = nil,
        error = nil,
    }
end

function FilesystemExecutor.execute(operation)
    local prepared_result = FilesystemExecutor.prepare(operation)

    if not prepared_result.ok then
        return prepared_result
    end

    local system_result = SystemExecutor.execute(prepared_result.command)

    return {
        ok = system_result.ok,
        operation = operation,
        command = prepared_result.command,
        executed = system_result.executed,
        exit_code = system_result.exit_code,
        reason = system_result.reason,
        system_result = system_result,
        error = system_result.error,
    }
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

return FilesystemExecutor
