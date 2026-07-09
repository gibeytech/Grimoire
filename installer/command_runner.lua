local CommandRunner = {}

local function resolve_mode(options)
    options = options or {}

    if options.dry_run ~= false then
        return "dry-run"
    end

    return "apply-safe"
end

function CommandRunner.prepare(command, options)
    local mode = resolve_mode(options)

    return {
        ok = true,
        mode = mode,
        command = command,
        executed = false,
        exit_code = nil,
    }
end

function CommandRunner.run(command, options)
    options = options or {}

    local result = CommandRunner.prepare(command, options)

    if result.mode == "dry-run" then
        print("[CommandRunner] Dry-run : commande préparée")
        print(command)
    elseif result.mode == "apply-safe" then
        print("[CommandRunner] Apply sécurisé : commande préparée mais non exécutée")
        print("[CommandRunner] Action système bloquée volontairement en RC1-21")
        print("[CommandRunner] Commande préparée :")
        print(command)
    else
        return {
            ok = false,
            mode = result.mode,
            command = command,
            executed = false,
            exit_code = nil,
            error = "Mode CommandRunner inconnu: " .. tostring(result.mode),
        }
    end

    return result
end

return CommandRunner
