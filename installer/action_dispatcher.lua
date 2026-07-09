local CommandRunner = require("installer.command_runner")
local FileOperations = require("installer.file_operations")
local ServiceOperation = require("installer.service_operation")
local ShellOperation = require("installer.shell_operation")
local ExecutionResult = require("installer.result.execution_result")

local ActionDispatcher = {}

local runners = {
    command = {
        runner = CommandRunner,
        input = function(action)
            return action.command
        end,
        result_key = "runner",
    },

    file_operation = {
        runner = FileOperations,
        input = function(action)
            return action.operation
        end,
        result_key = "operation",
    },

    service_operation = {
        runner = ServiceOperation,
        input = function(action)
            return action
        end,
        result_key = "service",
    },

    shell_operation = {
        runner = ShellOperation,
        input = function(action)
            return action
        end,
        result_key = "shell",
    },
}

local function action_label(action)
    return tostring(action.manager) .. "/" .. tostring(action.name)
end

local function action_title(action)
    if action.type == "command" then
        return "Commande"
    end

    if action.type == "file_operation" then
        return "Opération fichier"
    end

    if action.type == "service_operation" then
        return "Service"
    end

    if action.type == "shell_operation" then
        return "Shell"
    end

    return "Action"
end

local function result_details(action, runner_config, runner_result)
    local details = {
        action = action,
    }

    details[runner_config.result_key] = runner_result

    if action.type == "service_operation" then
        details.operation = runner_result.operation
    end

    if action.type == "shell_operation" then
        details.module = runner_result.module
        details.runtime = runner_result.runtime
    end

    return details
end

local function dispatch_registered_action(action, options, runner_config)
    print("[ActionDispatcher] " .. action_title(action) .. " : " .. action_label(action))

    local runner_result = runner_config.runner.run(runner_config.input(action), options)
    local details = result_details(action, runner_config, runner_result)

    if not runner_result.ok then
        return ExecutionResult.fail(action.manager, runner_result.error, {
            dry_run = options.dry_run ~= false,
            actions = 1,
            command = action.command,
            details = details,
        })
    end

    return ExecutionResult.ok(action.manager, {
        dry_run = options.dry_run ~= false,
        actions = 1,
        command = action.command,
        details = details,
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

    local runner_config = runners[action.type]

    if not runner_config then
        return ExecutionResult.fail(action.manager or "unknown", "Type d'action inconnu: " .. tostring(action.type), {
            dry_run = options.dry_run ~= false,
            actions = 0,
            details = {
                action = action,
            },
        })
    end

    return dispatch_registered_action(action, options, runner_config)
end

return ActionDispatcher
