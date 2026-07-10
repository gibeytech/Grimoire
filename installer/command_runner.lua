local SystemExecutor = require("installer.system_executor")

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

local function create_result(command, mode, options)
    options = options or {}

    return {
        ok = true,
        mode = mode,
        command = command,
        prepared = true,
        simulated = false,
        executed = false,
        exit_code = nil,
        reason = nil,
        timed_out = false,
        interrupted = false,
        timeout_seconds = options.timeout_seconds,
        kill_after_seconds = options.kill_after_seconds,
        error = nil,
    }
end

function CommandRunner.prepare(command, options)
    options = options or {}

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
            reason = nil,
            timed_out = false,
            interrupted = false,
            timeout_seconds = options.timeout_seconds,
            kill_after_seconds = options.kill_after_seconds,
            error = "Commande invalide",
        }
    end

    return create_result(command, mode, options)
end

function CommandRunner.simulate(result)
    if not result or not result.ok then
        return result
    end

    result.simulated = true
    result.executed = false
    result.exit_code = nil
    result.reason = nil
    result.timed_out = false
    result.interrupted = false

    if result.mode == "dry-run" then
        print("[CommandRunner] Dry-run : commande préparée")
        print(result.command)
    elseif result.mode == "apply-safe" then
        print("[CommandRunner] Apply sécurisé : commande préparée mais non exécutée")
        print("[CommandRunner] Action système bloquée volontairement")
        print("[CommandRunner] Commande préparée :")
        print(result.command)
    else
        print("[CommandRunner] Simulation : mode " .. tostring(result.mode))
        print(result.command)
    end

    return result
end

function CommandRunner.execute(result, options)
    if not result or not result.ok then
        return result
    end

    if result.mode ~= "apply-real" then
        return CommandRunner.simulate(result)
    end

    print("[CommandRunner] Apply réel : exécution de la commande")
    print(result.command)

    options = options or {}

    local system_result = SystemExecutor.execute(
        result.command,
        {
            timeout_seconds = options.timeout_seconds
                or result.timeout_seconds,
            kill_after_seconds = options.kill_after_seconds
                or result.kill_after_seconds,
        }
    )

    return {
        ok = system_result.ok,
        mode = result.mode,
        command = result.command,
        prepared = true,
        simulated = false,
        executed = system_result.executed,
        exit_code = system_result.exit_code,
        reason = system_result.reason,
        timed_out = system_result.timed_out == true,
        interrupted = system_result.interrupted == true,
        timeout_seconds = system_result.timeout_seconds,
        kill_after_seconds = system_result.kill_after_seconds,
        system = system_result,
        error = system_result.error,
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
        return CommandRunner.execute(result, options)
    end

    return {
        ok = false,
        mode = result.mode,
        command = command,
        prepared = result.prepared == true,
        simulated = false,
        executed = false,
        exit_code = nil,
        reason = nil,
        timed_out = false,
        interrupted = false,
        timeout_seconds = result.timeout_seconds,
        kill_after_seconds = result.kill_after_seconds,
        error = "Mode CommandRunner inconnu: " .. tostring(result.mode),
    }
end

return CommandRunner
