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
        error = nil,
    }
end

local function operation_is_valid(operation)
    if type(operation) ~= "table" then
        return false
    end

    if not operation.type or tostring(operation.type) == "" then
        return false
    end

    if not operation.source or tostring(operation.source) == "" then
        return false
    end

    return true
end

local function print_operation(operation)
    operation = operation or {}

    print("[FileOperations] Type        : " .. tostring(operation.type))
    print("[FileOperations] Source      : " .. tostring(operation.source))
    print("[FileOperations] Destination : " .. tostring(operation.destination))
end

function FileOperations.prepare(operation, options)
    local mode = resolve_mode(options)

    if not operation_is_valid(operation) then
        return {
            ok = false,
            mode = mode,
            operation = operation,
            prepared = false,
            simulated = false,
            executed = false,
            error = "Opération fichier invalide",
        }
    end

    return create_result(operation, mode)
end

function FileOperations.simulate(result)
    if not result or not result.ok then
        return result
    end

    result.simulated = true
    result.executed = false

    if result.mode == "dry-run" then
        print("[FileOperations] Dry-run : opération préparée")
    elseif result.mode == "apply-safe" then
        print("[FileOperations] Apply sécurisé : opération préparée mais non exécutée")
        print("[FileOperations] Action fichier bloquée volontairement en RC2-03")
    else
        print("[FileOperations] Simulation : mode " .. tostring(result.mode))
    end

    print_operation(result.operation)

    return result
end

function FileOperations.execute(result)
    if not result or not result.ok then
        return result
    end

    if result.mode ~= "apply-real" then
        return FileOperations.simulate(result)
    end

    return {
        ok = false,
        mode = result.mode,
        operation = result.operation,
        prepared = true,
        simulated = false,
        executed = false,
        error = "Mode apply-real non activé en RC2-03",
    }
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
        error = "Mode FileOperations inconnu: " .. tostring(result.mode),
    }
end

return FileOperations
