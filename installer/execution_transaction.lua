local FilesystemRollback = require(
    "installer.filesystem_rollback"
)

local ServiceRollback = require(
    "installer.service_rollback"
)

local ShellRollback = require(
    "installer.shell_rollback"
)

local HyprActivationRollback = require(
    "installer.hypr_activation_rollback"
)

local HyprActivationCommit = require(
    "installer.hypr_activation_commit"
)

local ExecutionTransaction = {}
ExecutionTransaction.__index = ExecutionTransaction

local function clone_table(value)
    if type(value) ~= "table" then
        return nil
    end

    local clone = {}

    for key, item in pairs(value) do
        clone[key] = item
    end

    return clone
end

local function create_result(mode, status)
    return {
        attempted = false,
        ok = true,
        status = status,
        mode = mode,
        total_actions = 0,
        successful_actions = 0,
        failed_actions = 0,
        executed_actions = 0,
        results = {},
        error = nil,
    }
end

local function compensation_is_safe(entry)
    if type(entry) ~= "table"
        or entry.ok ~= true
        or entry.executed ~= true
    then
        return false
    end

    local compensation =
        entry.compensation

    return type(compensation) == "table"
        and compensation.status == "ready"
        and compensation.eligible == true
        and compensation.reversible == true
end

local function create_internal_failure(
    metadata,
    phase,
    error_message
)
    return {
        ok = false,
        mode = "apply-real",
        status = "failed",
        phase = phase,
        metadata = metadata,
        compensation_type =
            metadata
            and metadata.compensation_type
            or nil,
        destination =
            metadata
            and metadata.destination
            or nil,
        command = nil,
        prepared = false,
        simulated = false,
        executed = false,
        removed = false,
        already_absent = false,
        exit_code = nil,
        reason = nil,
        stdout = "",
        stderr = "",
        system_result = nil,
        error =
            "Erreur interne pendant "
                .. tostring(phase)
                .. " : "
                .. tostring(error_message),
    }
end

local ROLLBACK_RUNNERS = {
    filesystem = FilesystemRollback,
    service = ServiceRollback,
    shell = ShellRollback,
    hypr_activation =
        HyprActivationRollback,
}

local COMMIT_RUNNERS = {
    hypr_activation =
        HyprActivationCommit,
}

local function run_metadata(
    runners,
    metadata,
    phase
)
    local runner =
        metadata
        and runners[metadata.kind]
        or nil

    if not runner then
        return create_internal_failure(
            metadata,
            phase,
            "Type de compensation inconnu : "
                .. tostring(
                    metadata
                    and metadata.kind
                )
        )
    end

    local call_ok, result_or_error =
        pcall(
            runner.run,
            metadata,
            {
                dry_run = false,
                apply_real = true,
            }
        )

    if not call_ok then
        return create_internal_failure(
            metadata,
            phase,
            result_or_error
        )
    end

    if type(result_or_error)
        ~= "table"
    then
        return create_internal_failure(
            metadata,
            phase,
            "Résultat transactionnel invalide"
        )
    end

    return result_or_error
end

local function run_compensation(metadata)
    return run_metadata(
        ROLLBACK_RUNNERS,
        metadata,
        "le rollback"
    )
end

local function run_commit_cleanup(metadata)
    return run_metadata(
        COMMIT_RUNNERS,
        metadata,
        "la finalisation du commit"
    )
end

function ExecutionTransaction.new(data)
    data = data or {}

    return setmetatable({
        mode = data.mode or "dry-run",
        compensations = {},
    }, ExecutionTransaction)
end

function ExecutionTransaction.not_required(
    mode,
    status
)
    return create_result(
        mode or "dry-run",
        status or "not-required"
    )
end

function ExecutionTransaction:register(entry)
    if not compensation_is_safe(entry) then
        return false
    end

    table.insert(self.compensations, {
        sequence = entry.sequence or 0,
        total = entry.total or 0,
        type = entry.type or "unknown",
        manager = entry.manager or "unknown",
        name = entry.name or "unknown",
        compensation = clone_table(
            entry.compensation
        ),
    })

    return true
end

function ExecutionTransaction:count()
    return #self.compensations
end

function ExecutionTransaction:commit()
    if self.mode ~= "apply-real" then
        return create_result(
            self.mode,
            "not-applicable"
        )
    end

    local pending = {}

    for _, registered in ipairs(
        self.compensations
    ) do
        local kind =
            registered.compensation
            and registered.compensation.kind

        if COMMIT_RUNNERS[kind] then
            table.insert(
                pending,
                registered
            )
        end
    end

    if #pending == 0 then
        return create_result(
            self.mode,
            "committed"
        )
    end

    local commit =
        create_result(
            self.mode,
            "running"
        )

    commit.attempted = true
    commit.total_actions = #pending

    for index, registered in ipairs(
        pending
    ) do
        print("")
        print(
            "[ExecutionTransaction] Commit "
                .. tostring(index)
                .. "/"
                .. tostring(#pending)
                .. " : "
                .. tostring(
                    registered.manager
                )
                .. "/"
                .. tostring(
                    registered.name
                )
        )

        local result =
            run_commit_cleanup(
                registered.compensation
            )

        table.insert(commit.results, {
            commit_sequence = index,
            original_sequence =
                registered.sequence,
            original_total =
                registered.total,
            type = registered.type,
            manager =
                registered.manager,
            name = registered.name,
            compensation =
                clone_table(
                    registered.compensation
                ),
            ok = result.ok == true,
            status =
                result.status
                or "unknown",
            result = result,
        })

        if result.executed == true then
            commit.executed_actions =
                commit.executed_actions + 1
        end

        if result.ok == true then
            commit.successful_actions =
                commit.successful_actions + 1
        else
            commit.failed_actions =
                commit.failed_actions + 1

            commit.ok = false
            commit.status = "failed"
            commit.error =
                "La finalisation du commit "
                    .. "transactionnel a échoué"

            return commit
        end
    end

    commit.status = "committed"

    return commit
end

function ExecutionTransaction:rollback()
    if self.mode ~= "apply-real" then
        return create_result(
            self.mode,
            "not-applicable"
        )
    end

    local total =
        #self.compensations

    if total == 0 then
        return create_result(
            self.mode,
            "nothing-to-rollback"
        )
    end

    local rollback =
        create_result(
            self.mode,
            "running"
        )

    rollback.attempted = true
    rollback.total_actions = total

    for index = total, 1, -1 do
        local registered =
            self.compensations[index]

        local rollback_sequence =
            total - index + 1

        print("")
        print(
            "[ExecutionTransaction] Rollback "
                .. tostring(
                    rollback_sequence
                )
                .. "/"
                .. tostring(total)
                .. " : "
                .. tostring(
                    registered.manager
                )
                .. "/"
                .. tostring(
                    registered.name
                )
        )

        local result =
            run_compensation(
                registered.compensation
            )

        table.insert(rollback.results, {
            rollback_sequence =
                rollback_sequence,
            original_sequence =
                registered.sequence,
            original_total =
                registered.total,
            type = registered.type,
            manager =
                registered.manager,
            name = registered.name,
            compensation =
                clone_table(
                    registered.compensation
                ),
            ok = result.ok == true,
            status =
                result.status
                or "unknown",
            result = result,
        })

        if result.executed == true then
            rollback.executed_actions =
                rollback.executed_actions + 1
        end

        if result.ok == true then
            rollback.successful_actions =
                rollback.successful_actions + 1
        else
            rollback.failed_actions =
                rollback.failed_actions + 1
        end
    end

    if rollback.failed_actions > 0 then
        rollback.ok = false
        rollback.status = "failed"
        rollback.error =
            "Une ou plusieurs compensations "
                .. "ont échoué"

        return rollback
    end

    rollback.status = "completed"

    return rollback
end

return ExecutionTransaction
