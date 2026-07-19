package.path =
    "./?.lua;./?/init.lua;"
        .. package.path

local Builder = require(
    "installer.builder"
)

local ExecutionPlanBuilder = require(
    "installer.execution_plan_builder"
)

local FilesystemPreflight = require(
    "installer.filesystem_preflight"
)

local ActionDispatcher = require(
    "installer.action_dispatcher"
)

local Executor = require(
    "installer.executor"
)

print(
    "== Profile RC4-D9C "
        .. "Filesystem Preflight Test =="
)

local execution_plan =
    ExecutionPlanBuilder.build(
        Builder.build("gibeytech"),
        {
            dry_run = false,
            apply_real = true,
        }
    )

local preflight =
    FilesystemPreflight.run(
        execution_plan,
        {
            dry_run = false,
            apply_real = true,
        }
    )

assert(preflight.ok == false)
assert(preflight.status == "blocked")
assert(preflight.file_operations == 10)

assert(preflight.counts.ready_create == 9)

assert(
    preflight.counts
        .already_satisfied == 0
)

assert(
    preflight.counts
        .conflict_empty == 0
)

assert(preflight.counts.conflict == 1)
assert(preflight.counts.invalid_source == 0)
assert(preflight.counts.blocking == 1)

local expected = {
    [9] = "ready-create",
    [10] = "ready-create",
    [11] = "ready-create",
    [12] = "ready-create",
    [13] = "ready-create",
    [14] = "ready-create",
    [15] = "conflict",
    [16] = "ready-create",
    [17] = "ready-create",
    [18] = "ready-create",
}

for sequence, status in pairs(expected) do
    local entry =
        preflight.by_sequence[sequence]

    assert(type(entry) == "table")

    assert(
        entry.status == status,
        "Statut inattendu pour l'action "
            .. tostring(sequence)
            .. " : "
            .. tostring(entry.status)
    )
end

local original_dispatch =
    ActionDispatcher.dispatch

local dispatch_calls = 0

local call_ok, result_or_error =
    xpcall(
        function()
            ActionDispatcher.dispatch =
                function()
                    dispatch_calls =
                        dispatch_calls + 1

                    error(
                        "Aucune action ne doit "
                            .. "être dispatchée"
                    )
                end

            return Executor.execute(
                execution_plan,
                {
                    dry_run = false,
                    apply_real = true,
                }
            )
        end,
        debug.traceback
    )

ActionDispatcher.dispatch =
    original_dispatch

assert(call_ok, result_or_error)

local execution =
    result_or_error

assert(dispatch_calls == 0)
assert(execution.ok == false)

assert(
    execution.transaction_status
        == "preflight-failed"
)

assert(execution.executed_actions == 0)
assert(#execution.results == 0)
assert(#execution.journal == 0)

print("")
print("Créations prêtes    : 9")
print("Conflits            : 1")
print("Actions dispatchées : 0")

print("")
print(
    "RC4-D9C OK : seul config.fish "
        .. "bloque encore le profil."
)
