local CommandRunner = require("installer.command_runner")
local FileOperations = require("installer.file_operations")
local ExecutionResult = require("installer.result.execution_result")

local ActionDispatcher = {}

local function action_label(action)
    return tostring(action.manager) .. "/" .. tostring(action.name)
end

local function dispatch_command(action, options)
    print("[ActionDispatcher] Commande : " .. action_label(action))

    local runner_result = CommandRunner.run(action.command, options)

    if not runner_result.ok then
        return ExecutionResult.fail(action.manager, runner_result.error, {
            dry_run = options.dry_run ~= false,
            actions = 1,
            command = action.command,
            details = {
                action = action,
                runner = runner_result,
            },
        })
    end

    return ExecutionResult.ok(action.manager, {
        dry_run = options.dry_run ~= false,
        actions = 1,
        command = action.command,
        details = {
            action = action,
            runner = runner_result,
        },
    })
end

local function dispatch_file_operation(action, options)
    print("[ActionDispatcher] Opération fichier : " .. action_label(action))

    local operation_result = FileOperations.run(action.operation, options)

    if not operation_result.ok then
        return ExecutionResult.fail(action.manager, operation_result.error, {
            dry_run = options.dry_run ~= false,
            actions = 1,
            details = {
                action = action,
                operation = operation_result,
            },
        })
    end

    return ExecutionResult.ok(action.manager, {
        dry_run = options.dry_run ~= false,
        actions = 1,
        details = {
            action = action,
            operation = operation_result,
        },
    })
end

local function dispatch_service_operation(action, options)
    local dry_run = options.dry_run ~= false

    print("[ActionDispatcher] Service : " .. action_label(action))
    print("[ServiceOperation] " .. tostring(action.operation) .. " : " .. tostring(action.service))

    if dry_run then
        print("[ServiceOperation] Dry-run : aucune action systemctl exécutée")
    else
        print("[ServiceOperation] Apply sécurisé : service préparé mais non modifié")
        print("[ServiceOperation] Action systemctl bloquée volontairement en RC1-25")
    end

    return ExecutionResult.ok(action.manager, {
        dry_run = dry_run,
        actions = 1,
        details = {
            action = action,
            service = action.service,
            operation = action.operation,
            executed = false,
        },
    })
end

local function dispatch_shell_operation(action, options)
    local dry_run = options.dry_run ~= false

    print("[ActionDispatcher] Shell : " .. action_label(action))
    print("[ShellOperation] Module : " .. tostring(action.module))
    print("[ShellOperation] Runtime : " .. tostring(action.runtime))

    if dry_run then
        print("[ShellOperation] Dry-run : aucun déploiement shell exécuté")
    else
        print("[ShellOperation] Apply sécurisé : module shell préparé mais non déployé")
        print("[ShellOperation] Action shell bloquée volontairement en RC1-25")
    end

    return ExecutionResult.ok(action.manager, {
        dry_run = dry_run,
        actions = 1,
        details = {
            action = action,
            module = action.module,
            runtime = action.runtime,
            executed = false,
        },
    })
end

function ActionDispatcher.dispatch(action, options)
    options = options or {}

    if not action or not action.type then
        return ExecutionResult.fail("unknown", "Action invalide", {
            dry_run = options.dry_run ~= false,
            actions = 0,
            details = {
                action = action,
            },
        })
    end

    if action.type == "command" then
        return dispatch_command(action, options)
    end

    if action.type == "file_operation" then
        return dispatch_file_operation(action, options)
    end

    if action.type == "service_operation" then
        return dispatch_service_operation(action, options)
    end

    if action.type == "shell_operation" then
        return dispatch_shell_operation(action, options)
    end

    return ExecutionResult.fail(action.manager or "unknown", "Type d'action inconnu: " .. tostring(action.type), {
        dry_run = options.dry_run ~= false,
        actions = 0,
        details = {
            action = action,
        },
    })
end

return ActionDispatcher
