local ServiceSpec = {}

local VALID_OPERATIONS = {
    enable = true,
    disable = true,
}

local VALID_SCOPES = {
    system = true,
    user = true,
}

local function value_is_present(value)
    return value ~= nil
        and tostring(value) ~= ""
end

local function trim(value)
    return tostring(value):match("^%s*(.-)%s*$")
end

local function normalize_unit(value)
    if not value_is_present(value) then
        return nil, "Unité systemd manquante"
    end

    local unit = trim(value)

    if unit == "" then
        return nil, "Unité systemd manquante"
    end

    if unit:find("\0", 1, true) then
        return nil, "Unité systemd invalide"
    end

    if unit:find("%s") then
        return nil, "Une unité systemd ne peut pas contenir d’espace"
    end

    return unit, nil
end

local function normalize_operation(value)
    if not value_is_present(value) then
        return nil, "Opération service manquante"
    end

    local operation = trim(value):lower()

    if VALID_OPERATIONS[operation] ~= true then
        return nil,
            "Opération service inconnue : "
                .. tostring(operation)
    end

    return operation, nil
end

local function normalize_scope(value)
    if not value_is_present(value) then
        return nil, "Scope service manquant"
    end

    local scope = trim(value):lower()

    if VALID_SCOPES[scope] ~= true then
        return nil,
            "Scope service inconnu : "
                .. tostring(scope)
    end

    return scope, nil
end

function ServiceSpec.normalize(value, defaults)
    defaults = defaults or {}

    if type(defaults) ~= "table" then
        return nil, "Options de normalisation invalides"
    end

    local unit
    local operation
    local scope

    if type(value) == "string" then
        unit = value
        operation = defaults.operation
        scope = defaults.scope or "system"
    elseif type(value) == "table" then
        unit = value.unit
            or value.service
            or value.name

        operation = value.operation
            or defaults.operation

        scope = value.scope
            or defaults.scope
            or "system"
    else
        return nil, "Description de service invalide"
    end

    local normalized_unit, unit_error =
        normalize_unit(unit)

    if not normalized_unit then
        return nil, unit_error
    end

    local normalized_operation, operation_error =
        normalize_operation(operation)

    if not normalized_operation then
        return nil, operation_error
    end

    local normalized_scope, scope_error =
        normalize_scope(scope)

    if not normalized_scope then
        return nil, scope_error
    end

    return {
        unit = normalized_unit,
        service = normalized_unit,
        operation = normalized_operation,
        scope = normalized_scope,
    }, nil
end

local function add_error(errors, label, index, message)
    table.insert(
        errors,
        tostring(label)
            .. "["
            .. tostring(index)
            .. "] : "
            .. tostring(message)
    )
end

local function collect_list(
    definitions,
    errors,
    seen,
    list,
    defaults,
    label,
    require_explicit_fields
)
    if type(list) ~= "table" then
        table.insert(
            errors,
            tostring(label) .. " doit être une table"
        )

        return
    end

    for index, value in ipairs(list) do
        if require_explicit_fields then
            if type(value) ~= "table" then
                add_error(
                    errors,
                    label,
                    index,
                    "La description explicite doit être une table"
                )

                goto continue
            end

            if not value_is_present(value.operation) then
                add_error(
                    errors,
                    label,
                    index,
                    "Le champ operation est obligatoire"
                )

                goto continue
            end

            if not value_is_present(value.scope) then
                add_error(
                    errors,
                    label,
                    index,
                    "Le champ scope est obligatoire"
                )

                goto continue
            end
        end

        local definition, definition_error =
            ServiceSpec.normalize(value, defaults)

        if not definition then
            add_error(
                errors,
                label,
                index,
                definition_error
            )

            goto continue
        end

        local identity =
            definition.scope
                .. "\0"
                .. definition.unit

        if seen[identity] then
            add_error(
                errors,
                label,
                index,
                "Service dupliqué dans le même scope : "
                    .. definition.unit
            )

            goto continue
        end

        seen[identity] = true
        table.insert(definitions, definition)

        ::continue::
    end
end

function ServiceSpec.collect(config)
    local definitions = {}
    local errors = {}
    local seen = {}

    if config == nil then
        return definitions, errors
    end

    if type(config) ~= "table" then
        table.insert(
            errors,
            "Configuration services invalide"
        )

        return definitions, errors
    end

    local recognized_format = false

    if config.services ~= nil then
        recognized_format = true

        collect_list(
            definitions,
            errors,
            seen,
            config.services,
            {},
            "services",
            true
        )
    end

    if config.enabled ~= nil then
        recognized_format = true

        collect_list(
            definitions,
            errors,
            seen,
            config.enabled,
            {
                operation = "enable",
                scope = "system",
            },
            "enabled",
            false
        )
    end

    if config.disabled ~= nil then
        recognized_format = true

        collect_list(
            definitions,
            errors,
            seen,
            config.disabled,
            {
                operation = "disable",
                scope = "system",
            },
            "disabled",
            false
        )
    end

    if not recognized_format and #config > 0 then
        collect_list(
            definitions,
            errors,
            seen,
            config,
            {},
            "services",
            true
        )
    end

    return definitions, errors
end

return ServiceSpec
