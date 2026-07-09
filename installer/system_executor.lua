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

function SystemExecutor.execute(command)
    if not command or tostring(command) == "" then
        return {
            ok = false,
            command = command,
            executed = false,
            exit_code = nil,
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
        error = exit_code == 0 and nil or "Commande système échouée",
    }
end

return SystemExecutor
