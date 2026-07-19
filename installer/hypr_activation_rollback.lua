local SystemExecutor = require(
    "installer.system_executor"
)

local HyprActivationRollback = {}

local function shell_quote(value)
    return "'"
        .. tostring(value):gsub(
            "'",
            "'\\''"
        )
        .. "'"
end

local function trim(value)
    if value == nil then
        return ""
    end

    return tostring(value):match(
        "^%s*(.-)%s*$"
    ) or ""
end

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

local function path_is_safe(path)
    if type(path) ~= "string"
        or path == ""
        or path:sub(1, 1) ~= "/"
        or path == "/"
        or path:find("\0", 1, true)
    then
        return false
    end

    for component in path:gmatch("[^/]+") do
        if component == "."
            or component == ".."
        then
            return false
        end
    end

    return true
end

local function run(command, options)
    options = options or {}

    return SystemExecutor.execute(
        command,
        {
            timeout_seconds =
                options.timeout_seconds,
            kill_after_seconds =
                options.kill_after_seconds,
        }
    )
end

local function path_exists(path, options)
    local result = run(
        "test -e "
            .. shell_quote(path)
            .. " || test -L "
            .. shell_quote(path),
        options
    )

    return result.ok == true
end

local function file_hash(path, options)
    local result = run(
        "sha256sum -- "
            .. shell_quote(path)
            .. " | awk '{print $1}'",
        options
    )

    if not result.ok then
        return nil
    end

    local hash = trim(result.stdout)

    if hash == "" then
        return nil
    end

    return hash
end

local function validate_metadata(metadata)
    if type(metadata) ~= "table" then
        return false,
            "Métadonnées Hypr invalides"
    end

    if metadata.kind
        ~= "hypr_activation"
    then
        return false,
            "Type de compensation incompatible"
    end

    if metadata.status ~= "ready"
        or metadata.eligible ~= true
        or metadata.reversible ~= true
    then
        return false,
            "La compensation Hypr "
                .. "n’est pas prête"
    end

    if metadata.compensation_type
        ~= "restore-backup"
    then
        return false,
            "Type de rollback Hypr inconnu"
    end

    if metadata.operation_type
        ~= "ensure-line"
    then
        return false,
            "Opération Hypr incompatible"
    end

    if not path_is_safe(
        metadata.destination
    ) or not path_is_safe(
        metadata.backup
    ) then
        return false,
            "Chemin de restauration invalide"
    end

    if metadata.destination
        == metadata.backup
    then
        return false,
            "Destination et sauvegarde "
                .. "doivent être distinctes"
    end

    if type(metadata.original_hash)
        ~= "string"
        or metadata.original_hash == ""
    then
        return false,
            "Empreinte originale absente"
    end

    return true, nil
end

local function create_result(
    metadata,
    mode
)
    return {
        ok = false,
        mode = mode,
        status = "invalid",
        metadata = metadata,
        compensation_type =
            metadata
            and metadata.compensation_type
            or nil,
        destination =
            metadata
            and metadata.destination
            or nil,
        backup =
            metadata
            and metadata.backup
            or nil,
        original_hash =
            metadata
            and metadata.original_hash
            or nil,
        command = nil,
        prepared = false,
        simulated = false,
        executed = false,
        restored = false,
        already_restored = false,
        removed_backup = false,
        exit_code = nil,
        reason = nil,
        stdout = "",
        stderr = "",
        system_result = nil,
        error = nil,
    }
end

local function build_command(metadata)
    local destination =
        shell_quote(
            metadata.destination
        )

    local backup =
        shell_quote(
            metadata.backup
        )

    local expected_hash =
        shell_quote(
            metadata.original_hash
        )

    return table.concat({
        "set -eu;",
        "destination=" .. destination .. ";",
        "backup=" .. backup .. ";",
        "expected_hash=" .. expected_hash .. ";",
        "test -f \"$backup\";",
        "cp -f -- \"$backup\" \"$destination\";",
        "luac -p \"$destination\";",
        "current_hash=$(sha256sum --"
            .. " \"$destination\""
            .. " | awk '{print $1}');",
        "[ \"$current_hash\""
            .. " = \"$expected_hash\" ];",
        "rm -f -- \"$backup\";",
    }, " ")
end

function HyprActivationRollback.prepare(
    metadata,
    options
)
    local mode = resolve_mode(options)

    local result =
        create_result(metadata, mode)

    local valid, validation_error =
        validate_metadata(metadata)

    if not valid then
        result.error = validation_error
        return result
    end

    result.ok = true
    result.status = "prepared"
    result.prepared = true
    result.command =
        build_command(metadata)

    return result
end

function HyprActivationRollback.simulate(
    result
)
    if not result or not result.ok then
        return result
    end

    result.status = "simulated"
    result.simulated = true
    result.executed = false
    result.error = nil

    return result
end

function HyprActivationRollback.execute(
    result,
    options
)
    if not result or not result.ok then
        return result
    end

    if result.mode ~= "apply-real" then
        return HyprActivationRollback
            .simulate(result)
    end

    local metadata = result.metadata

    local backup_exists =
        path_exists(
            metadata.backup,
            options
        )

    if not backup_exists then
        local current_hash =
            file_hash(
                metadata.destination,
                options
            )

        if current_hash
            == metadata.original_hash
        then
            result.ok = true
            result.status =
                "already-restored"

            result.already_restored = true
            result.restored = false
            result.executed = false
            result.error = nil

            return result
        end

        result.ok = false
        result.status = "failed"
        result.error =
            "Sauvegarde absente et état "
                .. "original non vérifiable"

        return result
    end

    local system_result =
        run(result.command, options)

    result.system_result = system_result
    result.executed =
        system_result.executed == true

    result.exit_code =
        system_result.exit_code

    result.reason =
        system_result.reason

    result.stdout =
        system_result.stdout or ""

    result.stderr =
        system_result.stderr or ""

    if not system_result.ok then
        result.ok = false
        result.status = "failed"
        result.error =
            "Échec de la restauration Hypr : "
                .. tostring(
                    system_result.error
                )

        return result
    end

    result.ok = true
    result.status = "restored"
    result.restored = true
    result.already_restored = false
    result.removed_backup = true
    result.error = nil

    return result
end

function HyprActivationRollback.run(
    metadata,
    options
)
    options = options or {}

    local result =
        HyprActivationRollback.prepare(
            metadata,
            options
        )

    if not result.ok then
        return result
    end

    if result.mode == "apply-real" then
        return HyprActivationRollback.execute(
            result,
            options
        )
    end

    return HyprActivationRollback.simulate(
        result
    )
end

return HyprActivationRollback
