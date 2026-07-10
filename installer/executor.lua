local ActionDispatcher = require("installer.action_dispatcher")

local Executor = {}

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

local function failure_result(mode, failed_result, results)
    return {
        ok = false,
        dry_run = mode == "dry-run",
        mode = mode,
        failed_at = failed_result.manager,
        results = results,
        error = failed_result.error,
        executed_actions = 0,
    }
end

local function count_executed_actions(results)
    local total = 0

    for _, result in ipairs(results or {}) do
        local details = result.details or {}

        local runner_result =
            details.runner
            or details.operation
            or details.service
            or details.shell

        if runner_result and runner_result.executed == true then
            total = total + 1
        end
    end

    return total
end

local function print_mode(mode)
    if mode == "dry-run" then
        print("[Executor] Mode dry-run actif")
        return
    end

    if mode == "apply-safe" then
        print("[Executor] Mode apply sécurisé actif")
        print("[Executor] Aucune action système réelle ne sera exécutée")
        return
    end

    if mode == "apply-real" then
        print("[Executor] Mode apply réel actif")
        print("[Executor] Les actions compatibles pourront modifier le système")
        return
    end

    print("[Executor] Mode inconnu : " .. tostring(mode))
end

function Executor.run(execution_plan, options)
    options = options or {}

    local mode = resolve_mode(options)
    local dry_run = mode == "dry-run"
    local results = {}

    print("== Grimoire V3 Executor ==")
    print_mode(mode)

    if not execution_plan or type(execution_plan.getActions) ~= "function" then
        return {
            ok = false,
            dry_run = dry_run,
            mode = mode,
            failed_at = "executor",
            results = results,
            error = "Executor attend un ExecutionPlan",
            executed_actions = 0,
        }
    end

    for index, action in ipairs(execution_plan:getActions() or {}) do
        print("")
        print(
            "[Executor] Action "
                .. tostring(index)
                .. "/"
                .. tostring(execution_plan:countActions())
        )

        local result = ActionDispatcher.dispatch(action, options)
        table.insert(results, result)

        if not result.ok then
            return failure_result(mode, result, results)
        end
    end

    return {
        ok = true,
        dry_run = dry_run,
        mode = mode,
        results = results,
        executed_actions = count_executed_actions(results),
    }
end

function Executor.execute(execution_plan, options)
    return Executor.run(execution_plan, options)
end

return Executor
