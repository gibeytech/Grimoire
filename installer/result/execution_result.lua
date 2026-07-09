local ExecutionResult = {}

function ExecutionResult.ok(manager, data)
    data = data or {}

    return {
        ok = true,
        manager = manager,
        actions = data.actions or 0,
        dry_run = data.dry_run,
        command = data.command,
        details = data.details or {},
        error = nil,
    }
end

function ExecutionResult.fail(manager, error, data)
    data = data or {}

    return {
        ok = false,
        manager = manager,
        actions = data.actions or 0,
        dry_run = data.dry_run,
        command = data.command,
        details = data.details or {},
        error = error or "Erreur inconnue",
    }
end

return ExecutionResult
