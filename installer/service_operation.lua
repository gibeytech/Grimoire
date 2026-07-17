local ServiceExecutor = require(
    "installer.service_executor"
)

local ServiceCompensationMetadata = require(
    "installer.result.service_compensation_metadata"
)

local ServiceOperation = {}

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

local function from_executor_result(
    executor_result,
    mode
)
    return {
        ok = executor_result.ok == true,
        mode = mode,
        service = executor_result.service,
        unit = executor_result.unit,
        operation =
            executor_result.operation,
        scope = executor_result.scope,
        command = executor_result.command,
        inspect_command =
            executor_result.inspect_command,
        systemctl_path =
            executor_result.systemctl_path,
        sudo_path =
            executor_result.sudo_path,
        elevated =
            executor_result.elevated == true,
        prepared =
            executor_result.prepared == true,
        simulated = false,
        inspected =
            executor_result.inspected == true,
        executed =
            executor_result.executed == true,
        changed =
            executor_result.changed == true,
        already_satisfied =
            executor_result
                .already_satisfied == true,
        state_before =
            executor_result.state_before,
        state_after =
            executor_result.state_after,
        exit_code =
            executor_result.exit_code,
        reason = executor_result.reason,
        timed_out =
            executor_result.timed_out == true,
        interrupted =
            executor_result.interrupted == true,
        timeout_seconds =
            executor_result.timeout_seconds,
        kill_after_seconds =
            executor_result.kill_after_seconds,
        inspection_before =
            executor_result
                .inspection_before,
        inspection_after =
            executor_result
                .inspection_after,
        system = executor_result.system,
        compensation =
            executor_result.compensation,
        error = executor_result.error,
    }
end

local function print_operation(result)
    print(
        "[ServiceOperation] "
            .. tostring(result.operation)
            .. " ["
            .. tostring(result.scope)
            .. "] : "
            .. tostring(result.unit)
    )
end

local function print_commands(result)
    print(
        "[ServiceOperation] Inspection : "
            .. tostring(
                result.inspect_command
            )
    )

    print(
        "[ServiceOperation] Commande   : "
            .. tostring(result.command)
    )
end

function ServiceOperation.prepare(
    action,
    options
)
    local mode = resolve_mode(options)

    local executor_result =
        ServiceExecutor.prepare(
            action,
            options
        )

    executor_result.compensation =
        ServiceCompensationMetadata.not_executed(
            executor_result
        )

    return from_executor_result(
        executor_result,
        mode
    )
end

function ServiceOperation.simulate(result)
    if not result or not result.ok then
        return result
    end

    result.simulated = true
    result.inspected = false
    result.executed = false
    result.changed = false
    result.already_satisfied = false

    print_operation(result)

    if result.mode == "dry-run" then
        print(
            "[ServiceOperation] Dry-run : "
                .. "aucune action systemctl exécutée"
        )
    elseif result.mode == "apply-safe" then
        print(
            "[ServiceOperation] Apply sécurisé : "
                .. "service préparé mais non modifié"
        )
    else
        print(
            "[ServiceOperation] Simulation : mode "
                .. tostring(result.mode)
        )
    end

    print_commands(result)

    return result
end

function ServiceOperation.execute(
    result,
    options
)
    if not result or not result.ok then
        return result
    end

    if result.mode ~= "apply-real" then
        return ServiceOperation.simulate(result)
    end

    print_operation(result)

    print(
        "[ServiceOperation] Apply réel : "
            .. "inspection et convergence systemd"
    )

    print_commands(result)

    local executor_result =
        ServiceExecutor.execute({
            unit = result.unit,
            operation = result.operation,
            scope = result.scope,
        }, options)

    executor_result.compensation =
        ServiceCompensationMetadata.complete(
            executor_result
        )

    local final_result =
        from_executor_result(
            executor_result,
            result.mode
        )

    if final_result.ok then
        if final_result.already_satisfied then
            print(
                "[ServiceOperation] État déjà conforme : "
                    .. tostring(
                        final_result
                            .state_after
                            .unit_file_state
                    )
            )
        elseif final_result.changed then
            print(
                "[ServiceOperation] État modifié et vérifié : "
                    .. tostring(
                        final_result
                            .state_after
                            .unit_file_state
                    )
            )
        end
    end

    return final_result
end

function ServiceOperation.run(
    action,
    options
)
    options = options or {}

    local result =
        ServiceOperation.prepare(
            action,
            options
        )

    if not result.ok then
        return result
    end

    if result.mode == "dry-run"
        or result.mode == "apply-safe"
    then
        return ServiceOperation.simulate(
            result
        )
    end

    if result.mode == "apply-real" then
        return ServiceOperation.execute(
            result,
            options
        )
    end

    result.ok = false
    result.error =
        "Mode ServiceOperation inconnu: "
            .. tostring(result.mode)

    return result
end

return ServiceOperation
