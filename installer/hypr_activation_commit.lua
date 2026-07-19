local SystemExecutor = require(
    "installer.system_executor"
)

local HyprActivationCommit = {}

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

local function execution_options(options)
    options = options or {}

    return {
        timeout_seconds =
            options.timeout_seconds,
        kill_after_seconds =
            options.kill_after_seconds,
    }
end

local function run(command, options)
    return SystemExecutor.execute(
        command,
        execution_options(options)
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

local function exact_line_count(
    path,
    line,
    options
)
    local result = run(
        table.concat({
            "count=$(grep -Fxc --",
            shell_quote(line),
            shell_quote(path),
            "2>/dev/null || true);",
            "printf '%s' \"$count\"",
        }, " "),
        options
    )

    if not result.ok then
        return nil
    end

    return tonumber(trim(result.stdout))
end

local function validate_metadata(metadata)
    if type(metadata) ~= "table" then
        return false,
            "Métadonnées de commit Hypr invalides"
    end

    if metadata.kind ~= "hypr_activation" then
        return false,
            "Type de finalisation incompatible"
    end

    if metadata.status ~= "ready"
        or metadata.eligible ~= true
        or metadata.reversible ~= true
    then
        return false,
            "La finalisation Hypr n’est pas prête"
    end

    if metadata.compensation_type
        ~= "restore-backup"
    then
        return false,
            "Type de compensation Hypr incompatible"
    end

    if not path_is_safe(metadata.destination)
        or not path_is_safe(metadata.backup)
    then
        return false,
            "Chemin de finalisation Hypr invalide"
    end

    if metadata.destination
        == metadata.backup
    then
        return false,
            "La destination et la sauvegarde "
                .. "doivent être distinctes"
    end

    if type(metadata.line) ~= "string"
        or metadata.line == ""
        or metadata.line:find("\n", 1, true)
        or metadata.line:find("\r", 1, true)
    then
        return false,
            "Ligne d’activation Hypr invalide"
    end

    if type(metadata.original_hash)
        ~= "string"
        or metadata.original_hash == ""
    then
        return false,
            "Empreinte originale Hypr absente"
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
        line =
            metadata
            and metadata.line
            or nil,
        original_hash =
            metadata
            and metadata.original_hash
            or nil,
        command = nil,
        prepared = false,
        simulated = false,
        executed = false,
        cleaned = false,
        already_cleaned = false,
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
        shell_quote(metadata.destination)

    local backup =
        shell_quote(metadata.backup)

    local line =
        shell_quote(metadata.line)

    local original_hash =
        shell_quote(metadata.original_hash)

    return table.concat({
        "set -eu;",
        "destination=" .. destination .. ";",
        "backup=" .. backup .. ";",
        "line=" .. line .. ";",
        "original_hash=" .. original_hash .. ";",
        "test -f \"$destination\";",
        "test -f \"$backup\";",
        "luac -p \"$destination\";",
        "count=$(grep -Fxc --"
            .. " \"$line\" \"$destination\""
            .. " 2>/dev/null || true);",
        "[ \"$count\" -eq 1 ];",
        "backup_hash=$(sha256sum --"
            .. " \"$backup\""
            .. " | awk '{print $1}');",
        "[ \"$backup_hash\""
            .. " = \"$original_hash\" ];",
        "rm -f -- \"$backup\";",
        "if [ -e \"$backup\" ]"
            .. " || [ -L \"$backup\" ];"
            .. " then exit 79; fi;",
    }, " ")
end

function HyprActivationCommit.prepare(
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

function HyprActivationCommit.simulate(
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

function HyprActivationCommit.execute(
    result,
    options
)
    if not result or not result.ok then
        return result
    end

    if result.mode ~= "apply-real" then
        return HyprActivationCommit.simulate(
            result
        )
    end

    local metadata = result.metadata

    local backup_exists =
        path_exists(
            metadata.backup,
            options
        )

    if not backup_exists then
        local line_count =
            exact_line_count(
                metadata.destination,
                metadata.line,
                options
            )

        local syntax_result = run(
            "luac -p "
                .. shell_quote(
                    metadata.destination
                ),
            options
        )

        if line_count == 1
            and syntax_result.ok == true
        then
            result.ok = true
            result.status = "already-cleaned"
            result.already_cleaned = true
            result.cleaned = false
            result.executed = false
            result.error = nil

            return result
        end

        result.ok = false
        result.status = "failed"
        result.error =
            "Sauvegarde absente et activation "
                .. "non vérifiable"

        return result
    end

    local backup_hash =
        file_hash(
            metadata.backup,
            options
        )

    if backup_hash
        ~= metadata.original_hash
    then
        result.ok = false
        result.status = "failed"
        result.error =
            "L’empreinte de la sauvegarde Hypr "
                .. "est inattendue"

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
            "Échec du nettoyage de la "
                .. "sauvegarde Hypr : "
                .. tostring(
                    system_result.error
                )

        return result
    end

    result.ok = true
    result.status = "cleaned"
    result.cleaned = true
    result.already_cleaned = false
    result.error = nil

    return result
end

function HyprActivationCommit.run(
    metadata,
    options
)
    options = options or {}

    local result =
        HyprActivationCommit.prepare(
            metadata,
            options
        )

    if not result.ok then
        return result
    end

    if result.mode == "apply-real" then
        return HyprActivationCommit.execute(
            result,
            options
        )
    end

    return HyprActivationCommit.simulate(
        result
    )
end

return HyprActivationCommit
