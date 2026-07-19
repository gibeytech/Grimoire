local HyprActivationExecutor = require(
    "installer.hypr_activation_executor"
)

local HyprActivationOperation = {}

local function contract_from_action(action)
    action = action or {}

    return {
        destination = action.destination,
        loader = action.loader,
        backup = action.backup,
        line = action.line,
    }
end

local function print_contract(contract)
    print(
        "[HyprActivationOperation] Destination : "
            .. tostring(contract.destination)
    )

    print(
        "[HyprActivationOperation] Chargeur    : "
            .. tostring(contract.loader)
    )

    print(
        "[HyprActivationOperation] Sauvegarde  : "
            .. tostring(contract.backup)
    )

    print(
        "[HyprActivationOperation] Ligne       : "
            .. tostring(contract.line)
    )
end

function HyprActivationOperation.run(
    action,
    options
)
    options = options or {}

    local contract =
        contract_from_action(action)

    print_contract(contract)

    local result =
        HyprActivationExecutor.run(
            contract,
            options
        )

    if result.mode == "dry-run" then
        print(
            "[HyprActivationOperation] Dry-run : "
                .. tostring(result.status)
        )
    elseif result.mode == "apply-safe" then
        print(
            "[HyprActivationOperation] "
                .. "Apply sécurisé : "
                .. tostring(result.status)
        )
    elseif result.mode == "apply-real" then
        print(
            "[HyprActivationOperation] "
                .. "Apply réel : "
                .. tostring(result.status)
        )
    end

    return result
end

return HyprActivationOperation
