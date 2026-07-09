local CommandRunner = {}

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

local function create_result(command, mode)
    return {
        ok = true,
        mode = mode,
        command = command,
        prepared = true,
        simulated = false,
        executed = false,
        exit_code = nil,
    }
end

function CommandRunner.prepare(command, options)
    local mode = resolve_mode(options)

    if not command or tostring(command) == "" then
        return {
            ok = false,
            mode = mode,
            command = command,
            prepared = false,
            simulated = false,
            executed = false,
            exit_code = nil,
            error = "Commande invalide",
        }
    end

    return create_result(command, mode)
end

function CommandRunner.simulate(result)
    if not result or not result.ok then
        return result
    end

    result.simulated = true
    result.executed = false
    result.exit_code = nil

    if result.mode == "dry-run" then
        print("[CommandRunner] Dry-run : commande préparée")
        print(result.command)
    elseif result.mode == "apply-safe" then
        print("[CommandRunner] Apply sécurisé : commande préparée mais non exécutée")
        print("[CommandRunner] Action système bloquée volontairement en RC2-01")
        print("[CommandRunner] Commande préparée :")
        print(result.command)
    else
        print("[CommandRunner] Simulation : mode " .. tostring(result.mode))
        print(result.command)
    end

    return result
end

function CommandRunner.execute(result)
    if not result or not result.ok then
        return result
    end

    if result.mode ~= "apply-real" then
        return CommandRunner.simulate(result)
    end

    return {
        ok = false,
        mode = result.mode,
        command = result.command,
        prepared = true,
        simulated = false,
        executed = false,
        exit_code = nil,
        error = "Mode apply-real non activé en RC2-01",
    }
end

function CommandRunner.run(command, options)
    options = options or {}

    local result = CommandRunner.prepare(command, options)

    if not result.ok then
        return result
    end

    if result.mode == "dry-run" or result.mode == "apply-safe" then
        return CommandRunner.simulate(result)
    end

    if result.mode == "apply-real" then
        return CommandRunner.execute(result)
    end

    return {
        ok = false,
        mode = result.mode,
        command = command,
        prepared = result.prepared == true,
        simulated = false,
        executed = false,
        exit_code = nil,
        error = "Mode CommandRunner inconnu: " .. tostring(result.mode),
    }
end

return CommandRunner
