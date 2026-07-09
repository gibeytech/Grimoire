local FileOperations = {}

local function resolve_mode(options)
    options = options or {}

    if options.dry_run ~= false then
        return "dry-run"
    end

    return "apply-safe"
end

function FileOperations.prepare(operation, options)
    options = options or {}
    operation = operation or {}

    return {
        ok = true,
        mode = resolve_mode(options),
        operation = operation,
        executed = false,
        error = nil,
    }
end

function FileOperations.run(operation, options)
    local result = FileOperations.prepare(operation, options)
    local op = result.operation or {}

    if result.mode == "dry-run" then
        print("[FileOperations] Dry-run : opération préparée")
    elseif result.mode == "apply-safe" then
        print("[FileOperations] Apply sécurisé : opération préparée mais non exécutée")
        print("[FileOperations] Action fichier bloquée volontairement en RC1-24")
    else
        return {
            ok = false,
            mode = result.mode,
            operation = operation,
            executed = false,
            error = "Mode FileOperations inconnu: " .. tostring(result.mode),
        }
    end

    print("[FileOperations] Type        : " .. tostring(op.type))
    print("[FileOperations] Source      : " .. tostring(op.source))
    print("[FileOperations] Destination : " .. tostring(op.destination))

    return result
end

return FileOperations
