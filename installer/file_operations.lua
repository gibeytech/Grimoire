local FilesystemExecutor = require("installer.filesystem_executor")

local FileOperations = {}

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

local function print_operation(operation)
    operation = operation or {}

    print("[FileOperations] Type        : " .. tostring(operation.type))
    print("[FileOperations] Source      : " .. tostring(operation.source))
    print("[FileOperations] Destination : " .. tostring(operation.destination))
end

local function map_validation_error(error_message)
    if error_message == "Opération filesystem invalide" then
        return "Opération fichier invalide"
    end

    if error_message == "Type d'opération filesystem manquant" then
        return "Type d'opération fichier manquant"
    end

    if error_message == "Source d'opération filesystem manquante" then
        return "Source d'opération fichier manquante"
    end

    if error_message == "Destination d'opération filesystem manquante" then
        return "Destination d'opération fichier manquante"
    end

    local unknown_type = tostring(error_message):match(
        "^Type d'opération filesystem inconnu:%s*(.*)$"
    )

    if unknown_type then
        return "Type d'opération fichier inconnu: " .. unknown_type
    end

    return error_message
end

local function execution_error(operation, filesystem_result)
    if filesystem_result and filesystem_result.error then
        return table.concat({
            "Échec de l'opération fichier",
            tostring(operation.type),
            ":",
            tostring(filesystem_result.error),
        }, " ")
    end

    return "Échec de l'opération fichier " .. tostring(operation.type)
end

function FileOperations.prepare(operation, options)
    local mode = resolve_mode(options)
    local filesystem_result = FilesystemExecutor.prepare(operation)

    if not filesystem_result.ok then
        return create_invalid_result(
            operation,
            mode,
            map_validation_error(filesystem_result.error)
        )
    end

    local result = create_result(operation, mode)

    result.command = filesystem_result.command

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

    local filesystem_result = FilesystemExecutor.execute(result.operation)

    result.command = filesystem_result.command or result.command
    result.system_result = filesystem_result
    result.executed = filesystem_result.executed == true
    result.simulated = false

    if not filesystem_result.ok then
        result.ok = false
        result.error = execution_error(
            result.operation,
            filesystem_result
        )

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
