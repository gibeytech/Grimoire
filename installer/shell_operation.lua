local ShellOperation = {}

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
        module = action.module,
        runtime = action.runtime,
        prepared = true,
        simulated = false,
        executed = false,
        error = nil,
    }
end

local function action_is_valid(action)
    return type(action) == "table"
        and action.module
        and tostring(action.module) ~= ""
        and action.runtime
        and tostring(action.runtime) ~= ""
end

function ShellOperation.prepare(action, options)
    local mode = resolve_mode(options)

    if not action_is_valid(action) then
        return {
            ok = false,
            mode = mode,
            module = action and action.module or nil,
            runtime = action and action.runtime or nil,
            prepared = false,
            simulated = false,
            executed = false,
            error = "Opération shell invalide",
        }
    end

    return create_result(action, mode)
end

function ShellOperation.simulate(result)
    if not result or not result.ok then
        return result
    end

    result.simulated = true
    result.executed = false

    print("[ShellOperation] Module : " .. tostring(result.module))
    print("[ShellOperation] Runtime : " .. tostring(result.runtime))

    if result.mode == "dry-run" then
        print("[ShellOperation] Dry-run : aucun déploiement shell exécuté")
    elseif result.mode == "apply-safe" then
        print("[ShellOperation] Apply sécurisé : module shell préparé mais non déployé")
        print("[ShellOperation] Action shell bloquée volontairement en RC2-07")
    else
        print("[ShellOperation] Simulation : mode " .. tostring(result.mode))
    end

    return result
end

function ShellOperation.execute(result)
    if not result or not result.ok then
        return result
    end

    if result.mode ~= "apply-real" then
        return ShellOperation.simulate(result)
    end

    return {
        ok = false,
        mode = result.mode,
        module = result.module,
        runtime = result.runtime,
        prepared = true,
        simulated = false,
        executed = false,
        error = "Mode apply-real non activé en RC2-07",
    }
end

function ShellOperation.run(action, options)
    options = options or {}

    local result = ShellOperation.prepare(action, options)

    if not result.ok then
        return result
    end

    if result.mode == "dry-run" or result.mode == "apply-safe" then
        return ShellOperation.simulate(result)
    end

    if result.mode == "apply-real" then
        return ShellOperation.execute(result)
    end

    return {
        ok = false,
        mode = result.mode,
        module = action and action.module or nil,
        runtime = action and action.runtime or nil,
        prepared = result.prepared == true,
        simulated = false,
        executed = false,
        error = "Mode ShellOperation inconnu: " .. tostring(result.mode),
    }
end

return ShellOperation
