local HyprActivationCompensationMetadata = {}

local function normalize(contract)
    if type(contract) == "table" then
        return contract
    end

    return {}
end

local function create_base(
    contract,
    original_hash
)
    contract = normalize(contract)

    return {
        kind = "hypr_activation",
        status = "planned",
        eligible = false,
        reversible = false,
        compensation_type = nil,
        operation_type = "ensure-line",
        destination = contract.destination,
        loader = contract.loader,
        backup = contract.backup,
        line = contract.line,
        original_hash = original_hash,
        destination_existed_before = true,
        created_backup = false,
        changed_destination = false,
        reason = nil,
    }
end

function HyprActivationCompensationMetadata
    .prepare(
        contract,
        original_hash
    )
    local metadata =
        create_base(
            contract,
            original_hash
        )

    metadata.eligible = true
    metadata.compensation_type =
        "restore-backup"

    metadata.reason =
        "Compensation disponible après "
            .. "activation réussie"

    return metadata
end

function HyprActivationCompensationMetadata
    .not_executed(
        contract,
        original_hash,
        reason
    )
    local metadata =
        HyprActivationCompensationMetadata
            .prepare(
                contract,
                original_hash
            )

    metadata.status = "not-executed"
    metadata.reversible = false
    metadata.reason =
        reason
            or "L’activation n’a pas été exécutée"

    return metadata
end

function HyprActivationCompensationMetadata
    .complete(
        contract,
        original_hash,
        execution_result
    )
    local metadata =
        HyprActivationCompensationMetadata
            .prepare(
                contract,
                original_hash
            )

    if type(execution_result) ~= "table"
        or execution_result.executed ~= true
    then
        return HyprActivationCompensationMetadata
            .not_executed(
                contract,
                original_hash,
                "Aucun résultat d’exécution exploitable"
            )
    end

    if execution_result.ok ~= true then
        metadata.status = "failed"
        metadata.reversible = false
        metadata.reason =
            "L’activation a échoué"
        return metadata
    end

    metadata.status = "ready"
    metadata.reversible = true
    metadata.created_backup = true
    metadata.changed_destination = true
    metadata.reason = nil

    return metadata
end

return HyprActivationCompensationMetadata
