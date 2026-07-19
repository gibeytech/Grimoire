local SystemExecutor = require(
    "installer.system_executor"
)

local CompensationMetadata = require(
    "installer.result."
        .. "hypr_activation_compensation_metadata"
)

local HyprActivationExecutor = {}

local DEFAULT_LINE =
    'require("grimoire-loader")'

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

local function value_is_present(value)
    return value ~= nil
        and tostring(value) ~= ""
end

local function path_is_absolute(path)
    return value_is_present(path)
        and tostring(path):sub(1, 1) == "/"
end

local function path_is_safe(path)
    if not path_is_absolute(path) then
        return false
    end

    if tostring(path) == "/" then
        return false
    end

    if tostring(path):find(
        "\0",
        1,
        true
    ) then
        return false
    end

    for component in
        tostring(path):gmatch("[^/]+")
    do
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

local function command_succeeded(
    command,
    options
)
    local result = run(command, options)

    return result.ok == true, result
end

local function path_exists(path, options)
    return command_succeeded(
        "test -e "
            .. shell_quote(path)
            .. " || test -L "
            .. shell_quote(path),
        options
    )
end

local function regular_file_exists(
    path,
    options
)
    return command_succeeded(
        "test -f " .. shell_quote(path),
        options
    )
end

local function command_exists(
    command,
    options
)
    return command_succeeded(
        "command -v "
            .. shell_quote(command)
            .. " >/dev/null 2>&1",
        options
    )
end

local function file_hash(path, options)
    local result = run(
        "sha256sum -- "
            .. shell_quote(path)
            .. " | awk '{print $1}'",
        options
    )

    if not result.ok then
        return nil, result
    end

    local hash = trim(result.stdout)

    if hash == "" then
        return nil, result
    end

    return hash, result
end

local function exact_line_count(
    path,
    line,
    options
)
    local command = table.concat({
        "count=$(grep -Fxc --",
        shell_quote(line),
        shell_quote(path),
        "2>/dev/null || true);",
        "printf '%s' \"$count\"",
    }, " ")

    local result = run(command, options)

    if not result.ok then
        return nil, result
    end

    return tonumber(trim(result.stdout)),
        result
end

local function normalize_contract(contract)
    contract = contract or {}

    return {
        destination = contract.destination,
        loader = contract.loader,
        loader_source = contract.loader_source,
        backup = contract.backup,
        line = contract.line or DEFAULT_LINE,
    }
end

local function validate_contract(contract)
    if type(contract) ~= "table" then
        return false,
            "Contrat d’activation Hypr invalide"
    end

    local fields = {
        destination = contract.destination,
        loader = contract.loader,
        backup = contract.backup,
    }

    for name, path in pairs(fields) do
        if not path_is_safe(path) then
            return false,
                "Chemin d’activation invalide : "
                    .. tostring(name)
        end
    end

    if contract.destination == contract.loader
        or contract.destination == contract.backup
        or contract.loader == contract.backup
    then
        return false,
            "Les chemins d’activation doivent "
                .. "être distincts"
    end

    if not value_is_present(contract.line) then
        return false,
            "Ligne d’activation manquante"
    end

    if tostring(contract.line):find(
        "\n",
        1,
        true
    ) or tostring(contract.line):find(
        "\r",
        1,
        true
    ) then
        return false,
            "La ligne d’activation doit tenir "
                .. "sur une seule ligne"
    end

    return true, nil
end

local function create_inspection(contract)
    return {
        ok = false,
        status = "invalid",
        ready = false,
        blocking = true,
        contract = contract,
        destination = contract.destination,
        loader = contract.loader,
        loader_source = contract.loader_source,
        loader_from_plan = false,
        backup = contract.backup,
        line = contract.line,
        line_count = nil,
        original_hash = nil,
        reason = nil,
        error = nil,
    }
end

local function finalize(
    inspection,
    status,
    reason,
    blocking
)
    inspection.status = status
    inspection.reason = reason
    inspection.blocking =
        blocking == true

    inspection.ready =
        not inspection.blocking

    inspection.ok =
        not inspection.blocking

    if inspection.blocking then
        inspection.error = reason
    else
        inspection.error = nil
    end

    return inspection
end

function HyprActivationExecutor.inspect(
    raw_contract,
    options
)
    local contract =
        normalize_contract(raw_contract)

    local inspection =
        create_inspection(contract)

    local valid, validation_error =
        validate_contract(contract)

    if not valid then
        return finalize(
            inspection,
            "invalid",
            validation_error,
            true
        )
    end

    local target_exists =
        regular_file_exists(
            contract.destination,
            options
        )

    if not target_exists then
        return finalize(
            inspection,
            "invalid-destination",
            "Le fichier Hypr cible est absent",
            true
        )
    end

    local loader_exists =
        regular_file_exists(
            contract.loader,
            options
        )

    if not loader_exists
        and (
            options == nil
            or options.apply_real ~= true
        )
        and value_is_present(
            contract.loader_source
        )
    then
        loader_exists =
            regular_file_exists(
                contract.loader_source,
                options
            )

        inspection.loader_from_plan =
            loader_exists == true
    end

    if not loader_exists then
        return finalize(
            inspection,
            "invalid-loader",
            "Le chargeur Grimoire est absent",
            true
        )
    end

    local luac_exists =
        command_exists("luac", options)

    if not luac_exists then
        return finalize(
            inspection,
            "missing-validator",
            "La commande luac est indisponible",
            true
        )
    end

    local original_hash =
        file_hash(
            contract.destination,
            options
        )

    if not original_hash then
        return finalize(
            inspection,
            "hash-failed",
            "Impossible de calculer l’empreinte "
                .. "du fichier cible",
            true
        )
    end

    inspection.original_hash =
        original_hash

    local line_count =
        exact_line_count(
            contract.destination,
            contract.line,
            options
        )

    if line_count == nil then
        return finalize(
            inspection,
            "inspection-failed",
            "Impossible d’inspecter la ligne "
                .. "d’activation",
            true
        )
    end

    inspection.line_count = line_count

    if line_count == 1 then
        return finalize(
            inspection,
            "already-satisfied",
            "Le chargeur est déjà activé",
            false
        )
    end

    if line_count > 1 then
        return finalize(
            inspection,
            "duplicate-conflict",
            "La ligne d’activation est présente "
                .. "plusieurs fois",
            true
        )
    end

    local backup_exists =
        path_exists(
            contract.backup,
            options
        )

    if backup_exists then
        return finalize(
            inspection,
            "backup-conflict",
            "La sauvegarde transactionnelle "
                .. "existe déjà",
            true
        )
    end

    return finalize(
        inspection,
        "ready",
        "Le fichier peut être activé "
            .. "avec sauvegarde préalable",
        false
    )
end

local function backup_parent(path)
    local parent =
        tostring(path):match(
            "^(.*)/[^/]+$"
        )

    if parent == nil or parent == "" then
        return "/"
    end

    return parent
end

local function build_command(contract)
    local target =
        shell_quote(contract.destination)

    local loader =
        shell_quote(contract.loader)

    local backup =
        shell_quote(contract.backup)

    local line =
        shell_quote(contract.line)

    local parent =
        shell_quote(
            backup_parent(contract.backup)
        )

    return table.concat({
        "set -eu;",
        "target=" .. target .. ";",
        "loader=" .. loader .. ";",
        "backup=" .. backup .. ";",
        "line=" .. line .. ";",
        "test -f \"$target\";",
        "test -f \"$loader\";",
        "mkdir -p -- " .. parent .. ";",
        "if [ -e \"$backup\" ]"
            .. " || [ -L \"$backup\" ];"
            .. " then exit 76; fi;",
        "tmp=$(mktemp"
            .. " \"${target}.grimoire.XXXXXX\");",
        "committed=0;",
        "cleanup() {"
            .. " rm -f -- \"$tmp\";"
            .. " if [ \"$committed\" -ne 1 ];"
            .. " then rm -f -- \"$backup\";"
            .. " fi;"
            .. " };",
        "trap cleanup EXIT HUP INT TERM;",
        "cp -- \"$target\" \"$backup\";",
        "cp -- \"$target\" \"$tmp\";",
        "if [ -s \"$tmp\" ]"
            .. " && [ \"$(tail -c 1 \"$tmp\""
            .. " | wc -l)\" -eq 0 ];"
            .. " then printf '\\n' >> \"$tmp\";"
            .. " fi;",
        "printf '%s\\n' \"$line\" >> \"$tmp\";",
        "luac -p \"$tmp\";",
        "count=$(grep -Fxc --"
            .. " \"$line\" \"$tmp\""
            .. " 2>/dev/null || true);",
        "[ \"$count\" -eq 1 ];",
        "mv -f -- \"$tmp\" \"$target\";",
        "if ! luac -p \"$target\";"
            .. " then"
            .. " cp -f -- \"$backup\" \"$target\";"
            .. " rm -f -- \"$backup\";"
            .. " exit 77;"
            .. " fi;",
        "count=$(grep -Fxc --"
            .. " \"$line\" \"$target\""
            .. " 2>/dev/null || true);",
        "if [ \"$count\" -ne 1 ];"
            .. " then"
            .. " cp -f -- \"$backup\" \"$target\";"
            .. " rm -f -- \"$backup\";"
            .. " exit 78;"
            .. " fi;",
        "committed=1;",
        "trap - EXIT HUP INT TERM;",
    }, " ")
end

local function create_result(
    contract,
    inspection,
    mode
)
    return {
        ok = inspection.ok == true,
        mode = mode,
        status = inspection.status,
        contract = contract,
        destination = contract.destination,
        loader = contract.loader,
        loader_source = contract.loader_source,
        loader_from_plan =
            inspection.loader_from_plan
                == true,
        backup = contract.backup,
        line = contract.line,
        inspection = inspection,
        prepared = inspection.ok == true,
        simulated = false,
        executed = false,
        changed = false,
        already_satisfied =
            inspection.status
                == "already-satisfied",
        skipped = false,
        command = nil,
        system_result = nil,
        exit_code = nil,
        reason = inspection.reason,
        original_hash =
            inspection.original_hash,
        final_hash = nil,
        timed_out = false,
        interrupted = false,
        timeout_seconds = nil,
        kill_after_seconds = nil,
        compensation = nil,
        error = inspection.error,
    }
end

function HyprActivationExecutor.simulate(
    raw_contract,
    options,
    mode
)
    local contract =
        normalize_contract(raw_contract)

    local inspection =
        HyprActivationExecutor.inspect(
            contract,
            options
        )

    local result =
        create_result(
            contract,
            inspection,
            mode
        )

    if not inspection.ok then
        return result
    end

    result.simulated = true
    result.skipped =
        inspection.status
            == "already-satisfied"

    if inspection.status == "ready" then
        result.command =
            build_command(contract)

        result.compensation =
            CompensationMetadata.prepare(
                contract,
                inspection.original_hash
            )
    end

    return result
end

function HyprActivationExecutor.execute(
    raw_contract,
    options
)
    local contract =
        normalize_contract(raw_contract)

    local inspection =
        HyprActivationExecutor.inspect(
            contract,
            options
        )

    local result =
        create_result(
            contract,
            inspection,
            "apply-real"
        )

    if not inspection.ok then
        return result
    end

    if inspection.status
        == "already-satisfied"
    then
        result.ok = true
        result.skipped = true
        result.changed = false
        result.compensation = nil
        return result
    end

    result.command =
        build_command(contract)

    local system_result =
        run(result.command, options)

    result.system_result = system_result
    result.executed =
        system_result.executed == true

    result.exit_code =
        system_result.exit_code

    result.timed_out =
        system_result.timed_out == true

    result.interrupted =
        system_result.interrupted == true

    result.timeout_seconds =
        system_result.timeout_seconds

    result.kill_after_seconds =
        system_result.kill_after_seconds

    result.compensation =
        CompensationMetadata.complete(
            contract,
            inspection.original_hash,
            system_result
        )

    if not system_result.ok then
        result.ok = false
        result.status = "failed"
        result.error =
            "Échec de l’activation Hypr : "
                .. tostring(
                    system_result.error
                )

        return result
    end

    local verification =
        HyprActivationExecutor.inspect(
            contract,
            options
        )

    if verification.status
        ~= "already-satisfied"
    then
        result.ok = false
        result.status =
            "verification-failed"

        result.error =
            "L’activation Hypr n’est pas "
                .. "vérifiable après écriture"

        return result
    end

    result.ok = true
    result.status = "activated"
    result.changed = true
    result.already_satisfied = false
    result.skipped = false
    result.reason = nil
    result.error = nil

    result.final_hash =
        verification.original_hash

    return result
end

function HyprActivationExecutor.run(
    contract,
    options
)
    options = options or {}

    if options.dry_run ~= false then
        return HyprActivationExecutor.simulate(
            contract,
            options,
            "dry-run"
        )
    end

    if options.apply_real == true then
        return HyprActivationExecutor.execute(
            contract,
            options
        )
    end

    return HyprActivationExecutor.simulate(
        contract,
        options,
        "apply-safe"
    )
end

return HyprActivationExecutor
