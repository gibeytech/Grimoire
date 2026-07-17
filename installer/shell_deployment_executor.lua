local SystemExecutor = require(
   "installer.system_executor"
)

local FileOperations = require(
   "installer.file_operations"
)

local CompensationMetadata = require(
   "installer.result.compensation_metadata"
)

local ShellDeploymentExecutor = {}

local function shell_quote(value)
   local string_value = tostring(value)

   return "'"
      .. string_value:gsub(
         "'",
         "'\\''"
      )
      .. "'"
end

local function normalize_output(value)
   if value == nil then
      return ""
   end

   return tostring(value):match(
      "^%s*(.-)%s*$"
   ) or ""
end

local function clone_modules(modules)
   local clone = {}

   for _, module in ipairs(
      modules or {}
   ) do
      table.insert(clone, module)
   end

   return clone
end

local function join_path(parent, child)
   local normalized_parent =
      tostring(parent)

   while #normalized_parent > 1
      and normalized_parent:sub(-1) == "/"
   do
      normalized_parent =
         normalized_parent:sub(1, -2)
   end

   return normalized_parent
      .. "/"
      .. tostring(child)
end

local function destination_is_safe(destination)
   if destination == nil
      or tostring(destination) == ""
   then
      return false,
         "Destination shell manquante"
   end

   local normalized =
      tostring(destination)

   if normalized:find(
      "\0",
      1,
      true
   ) then
      return false,
         "Destination shell invalide"
   end

   if normalized:sub(1, 1) ~= "/" then
      return false,
         "La destination shell doit être absolue"
   end

   while #normalized > 1
      and normalized:sub(-1) == "/"
   do
      normalized =
         normalized:sub(1, -2)
   end

   if normalized == "/" then
      return false,
         "La racine système ne peut pas accueillir le shell"
   end

   for component in normalized:gmatch(
      "[^/]+"
   ) do
      if component == "."
         or component == ".."
      then
         return false,
            "La destination shell contient un segment dangereux"
      end
   end

   return true, normalized
end

local function filesystem_operation(
   contract,
   source,
   overwrite
)
   return {
      type = contract.strategy,
      source = source,
      destination =
         contract.destination,
      overwrite = overwrite == true,
   }
end

local function create_result(contract)
   local operation =
      filesystem_operation(
         contract,
         contract.source,
         false
      )

   return {
      ok = true,
      status = "prepared",
      runtime = contract.runtime,
      modules =
         clone_modules(
            contract.modules
         ),
      source = contract.source,
      source_resolved = nil,
      destination =
         contract.destination,
      destination_state = nil,
      strategy = contract.strategy,
      overwrite = contract.overwrite,
      entrypoint = contract.entrypoint,
      operation = operation,
      prepared = true,
      executed = false,
      changed = false,
      already_satisfied = false,
      skipped = false,
      command = nil,
      exit_code = nil,
      reason = nil,
      stdout = "",
      stderr = "",
      timed_out = false,
      interrupted = false,
      timeout_seconds = nil,
      kill_after_seconds = nil,
      system_result = nil,
      verification_result = nil,
      compensation =
         CompensationMetadata.prepare(
            operation
         ),
      error = nil,
   }
end

local function mark_not_executed(
   result,
   reason
)
   result.compensation =
      CompensationMetadata.not_executed(
         result.operation,
         reason
      )
end

local function fail(
   result,
   status,
   reason,
   error_message
)
   result.ok = false
   result.status = status
   result.executed = false
   result.changed = false
   result.already_satisfied = false
   result.skipped = false
   result.reason = reason
   result.error = error_message

   mark_not_executed(
      result,
      error_message
   )

   return result
end

local function run_system(command, options)
   return SystemExecutor.execute(
      command,
      options
   )
end

local function resolve_source(
   result,
   options
)
   local command =
      "realpath -e -- "
      .. shell_quote(result.source)

   local system_result =
      run_system(
         command,
         options
      )

   if not system_result.ok
      or system_result.stdout == nil
      or system_result.stdout == ""
   then
      result.system_result =
         system_result

      result.command = command
      result.exit_code =
         system_result.exit_code
      result.reason =
         system_result.reason
      result.stdout =
         system_result.stdout or ""
      result.stderr =
         system_result.stderr or ""

      return false,
         "Source shell introuvable : "
            .. tostring(result.source)
   end

   result.source_resolved =
      normalize_output(
         system_result.stdout
      )

   result.operation.source =
      result.source_resolved

   result.compensation =
      CompensationMetadata.prepare(
         result.operation
      )

   return true, nil
end

local function validate_source(
   result,
   options
)
   local directory_command =
      "test -d "
      .. shell_quote(
         result.source_resolved
      )

   local directory_result =
      run_system(
         directory_command,
         options
      )

   if not directory_result.ok then
      return false,
         "La source shell n’est pas un répertoire : "
            .. tostring(
               result.source_resolved
            )
   end

   local source_entrypoint =
      join_path(
         result.source_resolved,
         result.entrypoint
      )

   local entrypoint_command =
      "test -f "
      .. shell_quote(
         source_entrypoint
      )

   local entrypoint_result =
      run_system(
         entrypoint_command,
         options
      )

   if not entrypoint_result.ok then
      return false,
         "Entrypoint shell absent : "
            .. tostring(
               source_entrypoint
            )
   end

   return true, nil
end

local function inspect_destination(
   destination,
   options
)
   local quoted =
      shell_quote(destination)

   local command = table.concat({
      "if [ -L", quoted, "]; then",
      "printf '%s' symlink;",
      "elif [ -d", quoted, "]; then",
      "printf '%s' directory;",
      "elif [ -e", quoted, "]; then",
      "printf '%s' other;",
      "else",
      "printf '%s' absent;",
      "fi",
   }, " ")

   local system_result =
      run_system(
         command,
         options
      )

   if not system_result.ok then
      return nil,
         system_result,
         "Impossible d’inspecter la destination shell"
   end

   return normalize_output(
         system_result.stdout
      ),
      system_result,
      nil
end

local function compare_copy(
   result,
   options
)
   if result.destination_state
      ~= "directory"
   then
      return false, nil, nil
   end

   local command = table.concat({
      "diff -qr --",
      shell_quote(
         result.source_resolved
      ),
      shell_quote(
         result.destination
      ),
      ">/dev/null 2>&1",
   }, " ")

   local system_result =
      run_system(
         command,
         options
      )

   if system_result.ok then
      return true,
         system_result,
         nil
   end

   if system_result.executed == true
      and system_result.exit_code == 1
   then
      return false,
         system_result,
         nil
   end

   return nil,
      system_result,
      "Impossible de comparer le runtime Shell"
end

local function compare_symlink(
   result,
   options
)
   if result.destination_state
      ~= "symlink"
   then
      return false, nil, nil
   end

   local command =
      "readlink -f -- "
      .. shell_quote(
         result.destination
      )

   local system_result =
      run_system(
         command,
         options
      )

   if not system_result.ok then
      return false,
         system_result,
         nil
   end

   return normalize_output(
         system_result.stdout
      ) == result.source_resolved,
      system_result,
      nil
end

local function compare_destination(
   result,
   options
)
   if result.strategy == "copy" then
      return compare_copy(
         result,
         options
      )
   end

   if result.strategy == "symlink" then
      return compare_symlink(
         result,
         options
      )
   end

   return nil,
      nil,
      "Stratégie Shell inconnue : "
         .. tostring(result.strategy)
end

local function map_filesystem_result(
   result,
   filesystem_result
)
   result.operation =
      filesystem_result.operation
         or result.operation

   result.command =
      filesystem_result.command

   result.executed =
      filesystem_result.executed == true

   result.system_result =
      filesystem_result.system_result

   result.compensation =
      filesystem_result.compensation

   result.timed_out =
      filesystem_result.timed_out == true

   result.interrupted =
      filesystem_result.interrupted == true

   result.timeout_seconds =
      filesystem_result.timeout_seconds

   result.kill_after_seconds =
      filesystem_result.kill_after_seconds

   if type(result.system_result)
      == "table"
   then
      result.exit_code =
         result.system_result.exit_code

      result.stdout =
         result.system_result.stdout or ""

      result.stderr =
         result.system_result.stderr or ""
   end
end

local function verify_deployment(
   result,
   options
)
   local state,
      inspection_result,
      inspection_error =
      inspect_destination(
         result.destination,
         options
      )

   result.destination_state = state
   result.verification_result =
      inspection_result

   if not state then
      return false,
         inspection_error
   end

   local identical,
      comparison_result,
      comparison_error =
      compare_destination(
         result,
         options
      )

   result.verification_result =
      comparison_result
         or inspection_result

   if identical == nil then
      return false,
         comparison_error
   end

   if identical ~= true then
      return false,
         "Le runtime Shell déployé ne correspond pas à la source"
   end

   local deployed_entrypoint =
      join_path(
         result.destination,
         result.entrypoint
      )

   local entrypoint_result =
      run_system(
         "test -f "
            .. shell_quote(
               deployed_entrypoint
            ),
         options
      )

   if not entrypoint_result.ok then
      return false,
         "Entrypoint absent après déploiement : "
            .. tostring(
               deployed_entrypoint
            )
   end

   return true, nil
end

function ShellDeploymentExecutor.run(
   contract,
   options
)
   options = options or {}

   local result =
      create_result(contract)

   local safe,
      destination_or_error =
      destination_is_safe(
         result.destination
      )

   if not safe then
      return fail(
         result,
         "invalid",
         "invalid-destination",
         destination_or_error
      )
   end

   result.destination =
      destination_or_error

   result.operation.destination =
      result.destination

   local source_ok,
      source_error =
      resolve_source(
         result,
         options
      )

   if not source_ok then
      return fail(
         result,
         "invalid",
         "missing-source",
         source_error
      )
   end

   local source_valid,
      validation_error =
      validate_source(
         result,
         options
      )

   if not source_valid then
      return fail(
         result,
         "invalid",
         "invalid-source",
         validation_error
      )
   end

   local destination_state,
      inspection_result,
      inspection_error =
      inspect_destination(
         result.destination,
         options
      )

   result.destination_state =
      destination_state

   result.verification_result =
      inspection_result

   if not destination_state then
      return fail(
         result,
         "inspection-failed",
         "inspection-failed",
         inspection_error
      )
   end

   if destination_state ~= "absent" then
      local identical,
         comparison_result,
         comparison_error =
         compare_destination(
            result,
            options
         )

      result.verification_result =
         comparison_result
            or inspection_result

      if identical == nil then
         return fail(
            result,
            "inspection-failed",
            "comparison-failed",
            comparison_error
         )
      end

      if identical == true then
         result.status =
            "already-satisfied"

         result.reason =
            "already-satisfied"

         result.already_satisfied = true
         result.executed = false
         result.changed = false
         result.error = nil

         mark_not_executed(
            result,
            "Le runtime Shell est déjà conforme"
         )

         return result
      end

      if result.overwrite == "skip" then
         result.status = "skipped"

         result.reason =
            "destination-exists-skipped"

         result.skipped = true
         result.executed = false
         result.changed = false
         result.error = nil

         mark_not_executed(
            result,
            "Destination Shell ignorée par politique skip"
         )

         return result
      end

      if result.overwrite == "force" then
         return fail(
            result,
            "unsupported",
            "force-conflict-unsupported",
            "Le remplacement forcé d’un runtime Shell "
               .. "existant sera contractualisé en RC4-B3"
         )
      end

      return fail(
         result,
         "conflict",
         "destination-conflict",
         "La destination Shell existe et diffère de la source : "
            .. tostring(
               result.destination
            )
      )
   end

   local filesystem_result =
      FileOperations.run(
         result.operation,
         {
            dry_run = false,
            apply_real = true,
            timeout_seconds =
               options.timeout_seconds,
            kill_after_seconds =
               options.kill_after_seconds,
         }
      )

   map_filesystem_result(
      result,
      filesystem_result
   )

   if not filesystem_result.ok then
      result.ok = false
      result.status = "failed"
      result.changed = false

      result.reason =
         filesystem_result.reason
            or "deployment-failed"

      result.error =
         "Échec du déploiement Shell : "
            .. tostring(
               filesystem_result.error
            )

      return result
   end

   local verified,
      verification_error =
      verify_deployment(
         result,
         options
      )

   if not verified then
      result.ok = false
      result.status =
         "verification-failed"

      result.changed =
         result.executed == true

      result.reason =
         "verification-failed"

      result.error =
         verification_error

      return result
   end

   result.ok = true
   result.status = "deployed"
   result.changed =
      result.executed == true

   result.already_satisfied = false
   result.skipped = false
   result.reason = "deployed"
   result.error = nil

   return result
end

return ShellDeploymentExecutor
