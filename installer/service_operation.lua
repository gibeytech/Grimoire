local ServiceOperation = {}

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

local function create_result(action, mode)
    return {
        ok = true,
        mode = mode,
        service = action.service,
        operation = action.operation,
        prepared = true,
        simulated = false,
        executed = false,
        error = nil,
    }
end

local function action_is_valid(action)
    if type(action) ~= "table" then
        return false
    end

    if not action.service or tostring(action.service) == "" then
        return false
    end

    if not action.operation or tostring(action.operation) == "" then
        return false
    end

    return true
end

local function print_operation(result)
    print("[ServiceOperation] " .. tostring(result.operation) .. " : " .. tostring(result.service))
end

function ServiceOperation.prepare(action, options)
    local mode = resolve_mode(options)

    if not action_is_valid(action) then
        return {
            ok = false,
            mode = mode,
            service = action and action.service or nil,
            operation = action and action.operation or nil,
            prepared = false,
            simulated = false,
            executed = false,
            error = "Opération service invalide",
        }
    end

    return create_result(action, mode)
end

function ServiceOperation.simulate(result)
    if not result or not result.ok then
        return result
    end

    result.simulated = true
    result.executed = false

    print_operation(result)

    if result.mode == "dry-run" then
        print("[ServiceOperation] Dry-run : aucune action systemctl exécutée")
    elseif result.mode == "apply-safe" then
        print("[ServiceOperation] Apply sécurisé : service préparé mais non modifié")
        print("[ServiceOperation] Action systemctl bloquée volontairement en RC2-05")
    else
        print("[ServiceOperation] Simulation : mode " .. tostring(result.mode))
    end

    return result
end

function ServiceOperation.execute(result)
    if not result or not result.ok then
        return result
    end

    if result.mode ~= "apply-real" then
        return ServiceOperation.simulate(result)
    end

    return {
        ok = false,
        mode = result.mode,
        service = result.service,
        operation = result.operation,
        prepared = true,
        simulated = false,
        executed = false,
        error = "Mode apply-real non activé en RC2-05",
    }
end

function ServiceOperation.run(action, options)
    options = options or {}

    local result = ServiceOperation.prepare(action, options)

    if not result.ok then
        return result
    end

    if result.mode == "dry-run" or result.mode == "apply-safe" then
        return ServiceOperation.simulate(result)
    end

    if result.mode == "apply-real" then
        return ServiceOperation.execute(result)
    end

    return {
        ok = false,
        mode = result.mode,
        service = action and action.service or nil,
        operation = action and action.operation or nil,
        prepared = result.prepared == true,
        simulated = false,
        executed = false,
        error = "Mode ServiceOperation inconnu: " .. tostring(result.mode),
    }
end

return ServiceOperation
