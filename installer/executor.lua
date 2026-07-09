local ActionDispatcher = require("installer.action_dispatcher")

local Executor = {}

local function execution_mode(dry_run)
    if dry_run then
        return "dry-run"
    end

    return "apply-safe"
end

local function failure_result(dry_run, failed_result, results)
    return {
        ok = false,
        dry_run = dry_run,
        mode = execution_mode(dry_run),
        failed_at = failed_result.manager,
        results = results,
        error = failed_result.error,
        executed_actions = 0,
    }
end

local function count_executed_actions(results)
    local total = 0

    for _, result in ipairs(results or {}) do
        if result.details and result.details.action and result.details.action.executed == true then
            total = total + 1
        end
    end

    return total
end

function Executor.run(execution_plan, options)
    options = options or {}

    local dry_run = options.dry_run ~= false
    local results = {}

    print("== Grimoire V3 Executor ==")

    if dry_run then
        print("[Executor] Mode dry-run actif")
    else
        print("[Executor] Mode apply sécurisé actif")
        print("[Executor] Aucune action système réelle ne sera exécutée en RC1-25")
    end

    if not execution_plan or type(execution_plan.getActions) ~= "function" then
        return {
            ok = false,
            dry_run = dry_run,
            mode = execution_mode(dry_run),
            failed_at = "executor",
            results = results,
            error = "Executor attend un ExecutionPlan",
            executed_actions = 0,
        }
    end

    for index, action in ipairs(execution_plan:getActions() or {}) do
        print("")
        print("[Executor] Action " .. tostring(index) .. "/" .. tostring(execution_plan:countActions()))

        local result = ActionDispatcher.dispatch(action, options)
        table.insert(results, result)

        if not result.ok then
            return failure_result(dry_run, result, results)
        end
    end

    return {
        ok = true,
        dry_run = dry_run,
        mode = execution_mode(dry_run),
        results = results,
        executed_actions = count_executed_actions(results),
    }
end

function Executor.execute(execution_plan, options)
    return Executor.run(execution_plan, options)
end

return Executor
