local SystemExecutor = require("installer.system_executor")

local FileOperations = {}

local SUPPORTED_OPERATIONS = {
    copy = true,
    symlink = true,
}

local function resolve_mode(options)
    options = options or {}

    if options.dry_run ~= false then
        return "dry-run"
    end

    if options.apply_real == true then
        return "apply-real"
    end

    return "apply-safe"
end

local function shell_quote(value)
    local string_value = tostring(value)

    return "'" .. string_value:gsub("'", "'\\''") .. "'"
end

local function create_result(operation, mode)
    return {
        ok = true,
        mode = mode,
        operation = operation,
        prepared = true,
        simulated = false,
        executed = false,
        command = nil,
        system_result = nil,
        error = nil,
    }
end

local function create_invalid_result(operation, mode, error_message)
    return {
        ok = false,
        mode = mode,
        operation = operation,
        prepared = false,
        simulated = false,
        executed = false,
        command = nil,
        system_result = nil,
        error = error_message,
    }
end

local function value_is_present(value)
    return value ~= nil and tostring(value) ~= ""
end

local function validate_operation(operation)
    if type(operation) ~= "table" then
        return false, "Opération fichier invalide"
    end

    if not value_is_present(operation.type) then
        return false, "Type d'opération fichier manquant"
    end

    if not SUPPORTED_OPERATIONS[operation.type] then
        return false, "Type d'opération fichier inconnu: " .. tostring(operation.type)
    end

    if not value_is_present(operation.source) then
        return false, "Source d'opération fichier manquante"
    end

    if not value_is_present(operation.destination) then
        return false, "Destination d'opération fichier manquante"
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

local function print_operation(operation)
    operation = operation or {}

    print("[FileOperations] Type        : " .. tostring(operation.type))
    print("[FileOperations] Source      : " .. tostring(operation.source))
    print("[FileOperations] Destination : " .. tostring(operation.destination))
end

local function execution_error(operation, system_result)
    if system_result and system_result.error then
        return table.concat({
            "Échec de l'opération fichier",
            tostring(operation.type),
            ":",
            tostring(system_result.error),
        }, " ")
    end

    return "Échec de l'opération fichier " .. tostring(operation.type)
end

function FileOperations.prepare(operation, options)
    local mode = resolve_mode(options)
    local valid, validation_error = validate_operation(operation)

    if not valid then
        return create_invalid_result(operation, mode, validation_error)
    end

    local result = create_result(operation, mode)

    result.command = build_command(operation)

    if not result.command then
        return create_invalid_result(
            operation,
            mode,
            "Impossible de construire la commande de l'opération fichier"
        )
    end

    return result
end

function FileOperations.simulate(result)
    if not result or not result.ok then
        return result
    end

    result.simulated = true
    result.executed = false
    result.system_result = nil

    if result.mode == "dry-run" then
        print("[FileOperations] Dry-run : opération préparée")
    elseif result.mode == "apply-safe" then
        print("[FileOperations] Apply sécurisé : opération préparée mais non exécutée")
    else
        print("[FileOperations] Simulation : mode " .. tostring(result.mode))
    end

    print_operation(result.operation)
    print("[FileOperations] Commande    : " .. tostring(result.command))

    return result
end

function FileOperations.execute(result)
    if not result or not result.ok then
        return result
    end

    if result.mode ~= "apply-real" then
        return FileOperations.simulate(result)
    end

    print("[FileOperations] Apply réel : exécution de l'opération")
    print_operation(result.operation)
    print("[FileOperations] Commande    : " .. tostring(result.command))

    local system_result = SystemExecutor.execute(result.command)

    result.system_result = system_result
    result.executed = system_result.executed == true
    result.simulated = false

    if not system_result.ok then
        result.ok = false
        result.error = execution_error(result.operation, system_result)

        return result
    end

    result.ok = true
    result.error = nil

    return result
end

function FileOperations.run(operation, options)
    options = options or {}

    local result = FileOperations.prepare(operation, options)

    if not result.ok then
        return result
    end

    if result.mode == "dry-run" or result.mode == "apply-safe" then
        return FileOperations.simulate(result)
    end

    if result.mode == "apply-real" then
        return FileOperations.execute(result)
    end

    return {
        ok = false,
        mode = result.mode,
        operation = operation,
        prepared = result.prepared == true,
        simulated = false,
        executed = false,
        command = result.command,
        system_result = nil,
        error = "Mode FileOperations inconnu: " .. tostring(result.mode),
    }
end

return FileOperations
