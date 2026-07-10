local ServiceSpec = require(
    "installer.model.service_spec"
)

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

local function create_result(definition, mode)
    return {
        ok = true,
        mode = mode,
        service = definition.unit,
        unit = definition.unit,
        operation = definition.operation,
        scope = definition.scope,
        prepared = true,
        simulated = false,
        executed = false,
        error = nil,
    }
end

local function create_invalid_result(
    action,
    mode,
    error_message
)
    return {
        ok = false,
        mode = mode,
        service = action
            and (action.service or action.unit)
            or nil,
        unit = action
            and (action.unit or action.service)
            or nil,
        operation = action
            and action.operation
            or nil,
        scope = action
            and action.scope
            or nil,
        prepared = false,
        simulated = false,
        executed = false,
        error = error_message
            or "Opération service invalide",
    }
end

local function print_operation(result)
    print(
        "[ServiceOperation] "
            .. tostring(result.operation)
            .. " ["
            .. tostring(result.scope)
            .. "] : "
            .. tostring(result.unit)
    )
end

function ServiceOperation.prepare(action, options)
    local mode = resolve_mode(options)

    local definition, definition_error =
        ServiceSpec.normalize(action)

    if not definition then
        return create_invalid_result(
            action,
            mode,
            definition_error
                or "Opération service invalide"
        )
    end

    return create_result(definition, mode)
end

function ServiceOperation.simulate(result)
    if not result or not result.ok then
        return result
    end

    result.simulated = true
    result.executed = false

    print_operation(result)

    if result.mode == "dry-run" then
        print(
            "[ServiceOperation] Dry-run : "
                .. "aucune action systemctl exécutée"
        )
    elseif result.mode == "apply-safe" then
        print(
            "[ServiceOperation] Apply sécurisé : "
                .. "service préparé mais non modifié"
        )

        print(
            "[ServiceOperation] Action systemctl "
                .. "bloquée pendant RC4-A1"
        )
    else
        print(
            "[ServiceOperation] Simulation : mode "
                .. tostring(result.mode)
        )
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
        unit = result.unit,
        operation = result.operation,
        scope = result.scope,
        prepared = true,
        simulated = false,
        executed = false,
        error =
            "Mode apply-real non activé pendant RC4-A1",
    }
end

function ServiceOperation.run(action, options)
    options = options or {}

    local result = ServiceOperation.prepare(
        action,
        options
    )

    if not result.ok then
        return result
    end

    if result.mode == "dry-run"
        or result.mode == "apply-safe"
    then
        return ServiceOperation.simulate(result)
    end

    if result.mode == "apply-real" then
        return ServiceOperation.execute(result)
    end

    return create_invalid_result(
        action,
        result.mode,
        "Mode ServiceOperation inconnu: "
            .. tostring(result.mode)
    )
end

return ServiceOperation
