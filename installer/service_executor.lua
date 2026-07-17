local SystemExecutor = require(
    "installer.system_executor"
)

local ServiceSpec = require(
    "installer.model.service_spec"
)

local ServiceExecutor = {}

local DEFAULT_SYSTEMCTL_PATH =
    "/usr/bin/systemctl"

local DEFAULT_SUDO_PATH =
    "/usr/bin/sudo"

local ENABLED_STATES = {
    enabled = true,
    ["enabled-runtime"] = true,
}

local DISABLED_STATES = {
    disabled = true,
    static = true,
    indirect = true,
    generated = true,
    transient = true,
    masked = true,
    ["masked-runtime"] = true,
}

local function value_is_present(value)
    return value ~= nil
        and tostring(value) ~= ""
end

local function trim(value)
    if value == nil then
        return ""
    end

    return tostring(value):match("^%s*(.-)%s*$")
end

local function shell_quote(value)
    local string_value = tostring(value)

    return "'"
        .. string_value:gsub(
            "'",
            "'\\''"
        )
        .. "'"
end

local function normalize_absolute_path(
    value,
    label
)
    if not value_is_present(value) then
        return nil,
            tostring(label) .. " manquant"
    end

    local path = trim(value)

    if path:sub(1, 1) ~= "/" then
        return nil,
            tostring(label)
                .. " doit être un chemin absolu"
    end

    if path:find("\0", 1, true) then
        return nil,
            tostring(label) .. " invalide"
    end

    return path, nil
end

local function resolve_paths(definition, options)
    options = options or {}

    if type(options) ~= "table" then
        return nil,
            "Options ServiceExecutor invalides"
    end

    local systemctl_path, systemctl_error =
        normalize_absolute_path(
            options.systemctl_path
                or DEFAULT_SYSTEMCTL_PATH,
            "Chemin systemctl"
        )

    if not systemctl_path then
        return nil, systemctl_error
    end

    local elevated =
        definition.scope == "system"
        and options.elevate_system ~= false

    local sudo_path = nil

    if elevated then
        local sudo_error

        sudo_path, sudo_error =
            normalize_absolute_path(
                options.sudo_path
                    or DEFAULT_SUDO_PATH,
                "Chemin sudo"
            )

        if not sudo_path then
            return nil, sudo_error
        end
    end

    return {
        systemctl_path = systemctl_path,
        sudo_path = sudo_path,
        elevated = elevated,
    }, nil
end

local function build_systemctl_prefix(
    systemctl_path,
    scope
)
    local parts = {
        shell_quote(systemctl_path),
    }

    if scope == "user" then
        table.insert(parts, "--user")
    end

    return table.concat(parts, " ")
end

local function build_inspect_command(
    definition,
    paths
)
    return table.concat({
        build_systemctl_prefix(
            paths.systemctl_path,
            definition.scope
        ),
        "show",
        "--no-pager",
        "--property=LoadState",
        "--property=UnitFileState",
        "--",
        shell_quote(definition.unit),
    }, " ")
end

local function build_operation_command(
    definition,
    paths
)
    local parts = {}

    if paths.elevated then
        table.insert(
            parts,
            shell_quote(paths.sudo_path)
        )
    end

    table.insert(
        parts,
        build_systemctl_prefix(
            paths.systemctl_path,
            definition.scope
        )
    )

    table.insert(parts, definition.operation)
    table.insert(parts, "--")
    table.insert(
        parts,
        shell_quote(definition.unit)
    )

    return table.concat(parts, " ")
end

local function parse_properties(output)
    local properties = {}

    output = tostring(output or "")

    for line in (output .. "\n"):gmatch("(.-)\n") do
        local key, value =
            line:match("^([^=]+)=(.*)$")

        if key then
            properties[trim(key)] = trim(value)
        end
    end

    return properties
end

local function clone_state(state)
    if type(state) ~= "table" then
        return nil
    end

    return {
        load_state = state.load_state,
        unit_file_state =
            state.unit_file_state,
    }
end

local function state_satisfies(
    operation,
    state
)
    if type(state) ~= "table" then
        return false
    end

    local unit_file_state =
        state.unit_file_state

    if operation == "enable" then
        return ENABLED_STATES[
            unit_file_state
        ] == true
    end

    if operation == "disable" then
        return DISABLED_STATES[
            unit_file_state
        ] == true
    end

    return false
end

local function create_invalid_result(
    value,
    error_message
)
    return {
        ok = false,
        service = type(value) == "table"
            and (value.service or value.unit)
            or nil,
        unit = type(value) == "table"
            and (value.unit or value.service)
            or nil,
        operation = type(value) == "table"
            and value.operation
            or nil,
        scope = type(value) == "table"
            and value.scope
            or nil,
        command = nil,
        inspect_command = nil,
        systemctl_path = nil,
        sudo_path = nil,
        elevated = false,
        prepared = false,
        inspected = false,
        executed = false,
        changed = false,
        already_satisfied = false,
        state_before = nil,
        state_after = nil,
        exit_code = nil,
        reason = nil,
        timed_out = false,
        interrupted = false,
        timeout_seconds = nil,
        kill_after_seconds = nil,
        inspection_before = nil,
        inspection_after = nil,
        system = nil,
        error = error_message
            or "Description de service invalide",
    }
end

local function create_result(prepared)
    return {
        ok = true,
        service = prepared.unit,
        unit = prepared.unit,
        operation = prepared.operation,
        scope = prepared.scope,
        command = prepared.command,
        inspect_command =
            prepared.inspect_command,
        systemctl_path =
            prepared.systemctl_path,
        sudo_path = prepared.sudo_path,
        elevated = prepared.elevated == true,
        prepared = true,
        inspected = false,
        executed = false,
        changed = false,
        already_satisfied = false,
        state_before = nil,
        state_after = nil,
        exit_code = nil,
        reason = nil,
        timed_out = false,
        interrupted = false,
        timeout_seconds = nil,
        kill_after_seconds = nil,
        inspection_before = nil,
        inspection_after = nil,
        system = nil,
        error = nil,
    }
end

local function execution_options(options)
    options = options or {}

    return {
        timeout_seconds =
            options.timeout_seconds,
        kill_after_seconds =
            options.kill_after_seconds,
    }
end

local function apply_system_metadata(
    result,
    system_result
)
    result.system = system_result

    if type(system_result) ~= "table" then
        return
    end

    result.exit_code =
        system_result.exit_code

    result.reason =
        system_result.reason

    result.timed_out =
        system_result.timed_out == true

    result.interrupted =
        system_result.interrupted == true

    result.timeout_seconds =
        system_result.timeout_seconds

    result.kill_after_seconds =
        system_result.kill_after_seconds
end

local function inspect(prepared, options)
    local system_result =
        SystemExecutor.execute(
            prepared.inspect_command,
            execution_options(options)
        )

    local inspection = {
        ok = false,
        command = prepared.inspect_command,
        executed =
            system_result.executed == true,
        state = nil,
        system = system_result,
        error = nil,
    }

    if not system_result.ok then
        inspection.error =
            "Échec de l’inspection systemd : "
                .. tostring(
                    system_result.error
                )

        return inspection
    end

    local properties =
        parse_properties(
            system_result.stdout
        )

    if properties.LoadState == nil then
        inspection.error =
            "Propriété LoadState absente"

        return inspection
    end

    if properties.UnitFileState == nil then
        inspection.error =
            "Propriété UnitFileState absente"

        return inspection
    end

    inspection.ok = true

    inspection.state = {
        load_state =
            properties.LoadState,
        unit_file_state =
            properties.UnitFileState,
    }

    return inspection
end

function ServiceExecutor.prepare(
    value,
    options
)
    local definition, definition_error =
        ServiceSpec.normalize(value)

    if not definition then
        return create_invalid_result(
            value,
            definition_error
        )
    end

    local paths, paths_error =
        resolve_paths(
            definition,
            options
        )

    if not paths then
        return create_invalid_result(
            value,
            paths_error
        )
    end

    return {
        ok = true,
        service = definition.unit,
        unit = definition.unit,
        operation =
            definition.operation,
        scope = definition.scope,
        inspect_command =
            build_inspect_command(
                definition,
                paths
            ),
        command =
            build_operation_command(
                definition,
                paths
            ),
        systemctl_path =
            paths.systemctl_path,
        sudo_path = paths.sudo_path,
        elevated = paths.elevated,
        prepared = true,
        inspected = false,
        executed = false,
        changed = false,
        already_satisfied = false,
        state_before = nil,
        state_after = nil,
        exit_code = nil,
        reason = nil,
        timed_out = false,
        interrupted = false,
        timeout_seconds = nil,
        kill_after_seconds = nil,
        inspection_before = nil,
        inspection_after = nil,
        system = nil,
        error = nil,
    }
end

function ServiceExecutor.execute(
    value,
    options
)
    options = options or {}

    local prepared =
        ServiceExecutor.prepare(
            value,
            options
        )

    if not prepared.ok then
        return prepared
    end

    local result = create_result(prepared)

    local inspection_before =
        inspect(prepared, options)

    result.inspection_before =
        inspection_before

    result.inspected =
        inspection_before.executed == true

    apply_system_metadata(
        result,
        inspection_before.system
    )

    if not inspection_before.ok then
        result.ok = false
        result.error =
            inspection_before.error

        return result
    end

    result.state_before =
        clone_state(
            inspection_before.state
        )

    if result.state_before.load_state
        ~= "loaded"
    then
        result.ok = false
        result.reason = "unit-not-loaded"
        result.error =
            "Unité systemd indisponible : "
                .. tostring(result.unit)
                .. " (LoadState="
                .. tostring(
                    result
                        .state_before
                        .load_state
                )
                .. ")"

        return result
    end

    if state_satisfies(
        result.operation,
        result.state_before
    ) then
        result.ok = true
        result.executed = false
        result.changed = false
        result.already_satisfied = true
        result.state_after =
            clone_state(
                result.state_before
            )
        result.exit_code = 0
        result.reason =
            "already-satisfied"
        result.error = nil

        return result
    end

    local operation_system =
        SystemExecutor.execute(
            prepared.command,
            execution_options(options)
        )

    result.executed =
        operation_system.executed == true

    apply_system_metadata(
        result,
        operation_system
    )

    if not operation_system.ok then
        result.ok = false
        result.changed = false
        result.error =
            "Échec de l’opération systemd "
                .. tostring(result.operation)
                .. " sur "
                .. tostring(result.unit)
                .. " : "
                .. tostring(
                    operation_system.error
                )

        return result
    end

    local inspection_after =
        inspect(prepared, options)

    result.inspection_after =
        inspection_after

    if not inspection_after.ok then
        result.ok = false
        result.changed = false

        apply_system_metadata(
            result,
            inspection_after.system
        )

        result.error =
            "Opération systemd exécutée mais "
                .. "vérification finale impossible : "
                .. tostring(
                    inspection_after.error
                )

        return result
    end

    result.state_after =
        clone_state(
            inspection_after.state
        )

    if not state_satisfies(
        result.operation,
        result.state_after
    ) then
        result.ok = false
        result.changed = false
        result.reason =
            "state-mismatch"
        result.error =
            "État systemd final incompatible pour "
                .. tostring(result.unit)
                .. " : "
                .. tostring(
                    result
                        .state_after
                        .unit_file_state
                )

        return result
    end

    result.ok = true
    result.changed = true
    result.already_satisfied = false
    result.error = nil

    return result
end

function ServiceExecutor.run(
    value,
    options
)
    return ServiceExecutor.execute(
        value,
        options
    )
end

return ServiceExecutor
