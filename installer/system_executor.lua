local SystemExecutor = {}

local function normalize_exit_code(ok, reason, code)
    if ok == true then
        return 0
    end

    if type(ok) == "number" then
        return ok
    end

    if type(code) == "number" then
        return code
    end

    return 1
end

local function resolve_error(exit_code)
    if exit_code == 0 then
        return nil
    end

    return "Commande système échouée"
end

function SystemExecutor.execute(command)
    if not command or tostring(command) == "" then
        return {
            ok = false,
            command = command,
            executed = false,
            exit_code = nil,
            reason = nil,
            error = "Commande système invalide",
        }
    end

    local ok, reason, code = os.execute(command)
    local exit_code = normalize_exit_code(ok, reason, code)

    return {
        ok = exit_code == 0,
        command = command,
        executed = true,
        exit_code = exit_code,
        reason = reason,
        error = resolve_error(exit_code),
    }
end

return SystemExecutor
