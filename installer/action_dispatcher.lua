local CommandRunner = require("installer.command_runner")
local FileOperations = require("installer.file_operations")
local ServiceOperation = require("installer.service_operation")
local ShellOperation = require("installer.shell_operation")
local RetryPolicy = require("installer.retry_policy")
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

local function build_runner_options(action, options)
    local runner_options = {}

    for key, value in pairs(options or {}) do
        runner_options[key] = value
    end

    if action.timeout_seconds ~= nil then
        runner_options.timeout_seconds =
            action.timeout_seconds
    end

    if action.kill_after_seconds ~= nil then
        runner_options.kill_after_seconds =
            action.kill_after_seconds
    end

    return runner_options
end

local function summarize_attempt(attempt, result)
    return {
        attempt = attempt,
        ok = result.ok == true,
        executed = result.executed == true,
        exit_code = result.exit_code,
        reason = result.reason,
        timed_out = result.timed_out == true,
        interrupted = result.interrupted == true,
        error = result.error,
    }
end

local function attach_retry_metadata(
    runner_result,
    policy,
    attempts,
    stopped_reason
)
    runner_result.retry = {
        enabled = policy.enabled == true,
        replay_safe = policy.replay_safe == true,
        max_attempts = policy.max_attempts,
        attempts = #attempts,
        retried = #attempts > 1,
        exhausted = stopped_reason == "exhausted",
        stopped_reason = stopped_reason,
        retry_on_timeout = policy.retry_on_timeout == true,
        exit_codes = policy.exit_codes,
        attempt_results = attempts,
    }

    return runner_result
end

local function execute_with_retry(
    action,
    options,
    runner_config,
    policy
)
    local attempts = {}
    local runner_result = nil
    local stopped_reason = "disabled"
    local runner_options = build_runner_options(
        action,
        options
    )

    for attempt = 1, policy.max_attempts do
        if attempt > 1 then
            print(
                "[ActionDispatcher] Retry "
                    .. tostring(attempt)
                    .. "/"
                    .. tostring(policy.max_attempts)
                    .. " : "
                    .. action_label(action)
            )
        end

        runner_result = runner_config.runner.run(
            runner_config.input(action),
            runner_options
        )

        table.insert(
            attempts,
            summarize_attempt(attempt, runner_result)
        )

        local should_retry

        should_retry, stopped_reason =
            RetryPolicy.should_retry(
                policy,
                runner_result,
                attempt
            )

        if not should_retry then
            break
        end
    end

    return attach_retry_metadata(
        runner_result,
        policy,
        attempts,
        stopped_reason
    )
end

local function invalid_retry_result(
    action,
    options,
    error_message
)
    return ExecutionResult.fail(
        action.manager or "unknown",
        error_message,
        {
            dry_run = options.dry_run ~= false,
            actions = 0,
            command = action.command,
            details = {
                action = action,
                retry_error = error_message,
            },
        }
    )
end

local function dispatch_registered_action(action, options, runner_config)
    print("[ActionDispatcher] " .. action_title(action) .. " : " .. action_label(action))

    local retry_policy, retry_error =
        RetryPolicy.resolve(action)

    if not retry_policy then
        return invalid_retry_result(
            action,
            options,
            retry_error
        )
    end

    local runner_result = execute_with_retry(
        action,
        options,
        runner_config,
        retry_policy
    )

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
