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
    "== Profile RC4-D8 "
        .. "Filesystem Preflight Test =="
)

local installation_plan =
    Builder.build("gibeytech")

local execution_plan =
    ExecutionPlanBuilder.build(
        installation_plan,
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
assert(preflight.file_operations == 8)

assert(
    preflight.counts.ready_create == 6
)

assert(
    preflight.counts
        .already_satisfied == 0
)

assert(
    preflight.counts
        .conflict_empty == 0
)

assert(preflight.counts.conflict == 2)
assert(preflight.counts.invalid_source == 0)
assert(preflight.counts.blocking == 2)

local expected = {
    [9] = "ready-create",
    [10] = "ready-create",
    [11] = "conflict",
    [12] = "ready-create",
    [13] = "conflict",
    [14] = "ready-create",
    [15] = "ready-create",
    [16] = "ready-create",
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
print("Créations prêtes    : 6")
print("Destination vide    : 0")
print("Conflits            : 2")
print("Actions dispatchées : 0")

print("")
print(
    "RC4-D8 OK : le profil GibeyTech "
        .. "est refusé avant l’Action 1."
)
