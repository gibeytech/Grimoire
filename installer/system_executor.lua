local SystemExecutor = {}

local DEFAULT_KILL_AFTER_SECONDS = 2
local TIMEOUT_EXIT_CODES = {
   [124] = true,
   [137] = true,
}
local INTERRUPTED_EXIT_CODES = {
   [130] = true,
   [143] = true,
}

local function shell_quote(value)
   local string_value = tostring(value)

   return "'" .. string_value:gsub("'", "'\\''") .. "'"
end

local function normalize_positive_number(value, label)
   if value == nil then
      return nil, nil
   end

   if type(value) ~= "number"
      or value ~= value
      or value == math.huge
      or value == -math.huge
      or value <= 0
   then
      return nil, tostring(label) .. " invalide"
   end

   return value, nil
end

local function normalize_duration(value)
   local formatted = string.format("%.3f", value)

   formatted = formatted:gsub("0+$", "")
   formatted = formatted:gsub("%.$", "")

   return formatted .. "s"
end

local function resolve_execution_limits(options)
   if options == nil then
      return nil, nil, nil
   end

   if type(options) ~= "table" then
      return nil, nil, "Options SystemExecutor invalides"
   end

   local timeout_seconds, timeout_error =
      normalize_positive_number(
         options.timeout_seconds,
         "Timeout système"
      )

   if timeout_error then
      return nil, nil, timeout_error
   end

   local kill_after_seconds = nil

   if timeout_seconds ~= nil then
      kill_after_seconds =
         options.kill_after_seconds

      if kill_after_seconds == nil then
         kill_after_seconds =
            DEFAULT_KILL_AFTER_SECONDS
      end

      local kill_after_error

      kill_after_seconds, kill_after_error =
         normalize_positive_number(
            kill_after_seconds,
            "Délai d'arrêt forcé"
         )

      if kill_after_error then
         return nil, nil, kill_after_error
      end
   elseif options.kill_after_seconds ~= nil then
      local _, kill_after_error =
         normalize_positive_number(
            options.kill_after_seconds,
            "Délai d'arrêt forcé"
         )

      if kill_after_error then
         return nil, nil, kill_after_error
      end
   end

   return timeout_seconds, kill_after_seconds, nil
end

local function normalize_exit_code(ok, reason, code)
   if ok == true then
      return 0
   end

   if type(ok) == "number" then
      if ok > 255 and ok % 256 == 0 then
         return math.floor(ok / 256)
      end

      return ok
   end

   if type(code) == "number" then
      return code
   end

   return 1
end

local function resolve_timed_out(
   exit_code,
   timeout_seconds
)
   return timeout_seconds ~= nil
      and TIMEOUT_EXIT_CODES[exit_code] == true
end

local function resolve_interrupted(
   reason,
   exit_code,
   timed_out
)
   if timed_out then
      return false
   end

   if reason == "signal" then
      return true
   end

   return INTERRUPTED_EXIT_CODES[exit_code] == true
end

local function resolve_error(
   exit_code,
   timed_out,
   interrupted
)
   if exit_code == 0 then
      return nil
   end

   if timed_out then
      return "Commande système interrompue par timeout"
   end

   if interrupted then
      return "Commande système interrompue"
   end

   return "Commande système échouée"
end

local function path_is_in_tmp(path)
   return type(path) == "string"
      and path:match("^/tmp/") ~= nil
end

local function path_exists(path)
   if not path then
      return false
   end

   local file = io.open(path, "rb")

   if not file then
      return false
   end

   file:close()

   return true
end

local function remove_file(path)
   if not path or not path_exists(path) then
      return true, nil
   end

   local call_ok, removed, remove_error = pcall(
      os.remove,
      path
   )

   if not call_ok then
      return false, tostring(removed)
   end

   if removed == nil and path_exists(path) then
      return false, tostring(
         remove_error or "Suppression impossible"
      )
   end

   return true, nil
end

local function append_detail(message, detail)
   if not detail or tostring(detail) == "" then
      return message
   end

   return tostring(message) .. "; " .. tostring(detail)
end

local function create_temp_path()
   local call_ok, path_or_error, additional_error = pcall(
      os.tmpname
   )

   if not call_ok then
      return nil, tostring(path_or_error)
   end

   if type(path_or_error) ~= "string"
      or path_or_error == ""
   then
      return nil, tostring(
         additional_error
            or "os.tmpname n'a retourné aucun chemin"
      )
   end

   if not path_is_in_tmp(path_or_error) then
      local removed, remove_error = remove_file(path_or_error)

      local message =
         "Le chemin temporaire n'est pas situé dans /tmp"

      if not removed then
         message = append_detail(
            message,
            "nettoyage impossible: " .. tostring(remove_error)
         )
      end

      return nil, message
   end

   return path_or_error, nil
end

local function create_capture_paths()
   local stdout_path, stdout_error = create_temp_path()

   if not stdout_path then
      return nil, nil, stdout_error
   end

   local stderr_path, stderr_error = create_temp_path()

   if not stderr_path then
      local removed, remove_error = remove_file(stdout_path)

      local message = tostring(stderr_error)

      if not removed then
         message = append_detail(
            message,
            "nettoyage de stdout impossible: "
               .. tostring(remove_error)
         )
      end

      return nil, nil, message
   end

   if stdout_path == stderr_path then
      local removed, remove_error = remove_file(stdout_path)

      local message = "Les chemins de capture sont identiques"

      if not removed then
         message = append_detail(
            message,
            "nettoyage impossible: " .. tostring(remove_error)
         )
      end

      return nil, nil, message
   end

   return stdout_path, stderr_path, nil
end

local function cleanup_capture_paths(
   stdout_path,
   stderr_path
)
   local errors = {}

   local stdout_removed, stdout_error = remove_file(
      stdout_path
   )

   if not stdout_removed then
      table.insert(
         errors,
         "stdout: " .. tostring(stdout_error)
      )
   end

   local stderr_removed, stderr_error = remove_file(
      stderr_path
   )

   if not stderr_removed then
      table.insert(
         errors,
         "stderr: " .. tostring(stderr_error)
      )
   end

   if #errors > 0 then
      return false, table.concat(errors, "; ")
   end

   return true, nil
end

local function read_capture(path)
   local file, open_error = io.open(path, "rb")

   if not file then
      return nil, tostring(open_error)
   end

   local read_ok, content, read_error = pcall(
      file.read,
      file,
      "*a"
   )

   local close_ok, close_result, close_error = pcall(
      file.close,
      file
   )

   if not read_ok then
      return nil, tostring(content)
   end

   if content == nil then
      return nil, tostring(
         read_error or "Lecture impossible"
      )
   end

   if not close_ok then
      return nil, tostring(close_result)
   end

   if close_result == nil then
      return nil, tostring(
         close_error or "Fermeture impossible"
      )
   end

   return content, nil
end

local function build_timeout_command(
   command,
   timeout_seconds,
   kill_after_seconds
)
   if timeout_seconds == nil then
      return command
   end

   return table.concat({
      "/usr/bin/timeout",
      "--foreground",
      "--signal=TERM",
      "--kill-after="
         .. shell_quote(
            normalize_duration(
               kill_after_seconds
            )
         ),
      shell_quote(
         normalize_duration(timeout_seconds)
      ),
      "/bin/sh",
      "-c",
      shell_quote(command),
   }, " ")
end

local function build_captured_command(
   command,
   stdout_path,
   stderr_path
)
   return table.concat({
      "(",
      command,
      ")",
      ">",
      shell_quote(stdout_path),
      "2>",
      shell_quote(stderr_path),
   }, " ")
end

local function create_internal_error_result(
   command,
   message,
   details
)
   details = details or {}

   return {
      ok = false,
      command = command,
      executed = details.executed == true,
      exit_code = details.exit_code,
      reason = details.reason,
      stdout = details.stdout or "",
      stderr = details.stderr or "",
      timed_out = details.timed_out == true,
      interrupted = details.interrupted == true,
      timeout_seconds = details.timeout_seconds,
      kill_after_seconds =
         details.kill_after_seconds,
      error = "Erreur interne SystemExecutor: "
         .. tostring(message),
   }
end

local function create_invalid_result(
   command,
   error_message
)
   return {
      ok = false,
      command = command,
      executed = false,
      exit_code = nil,
      reason = nil,
      stdout = "",
      stderr = "",
      timed_out = false,
      interrupted = false,
      timeout_seconds = nil,
      kill_after_seconds = nil,
      error = error_message
         or "Commande système invalide",
   }
end

function SystemExecutor.execute(command, options)
   if not command or tostring(command) == "" then
      return create_invalid_result(command)
   end

   command = tostring(command)

   local timeout_seconds, kill_after_seconds,
      limits_error = resolve_execution_limits(options)

   if limits_error then
      return create_invalid_result(
         command,
         limits_error
      )
   end

   local stdout_path, stderr_path, capture_error =
      create_capture_paths()

   if not stdout_path or not stderr_path then
      return create_internal_error_result(
         command,
         "impossible de préparer les fichiers temporaires "
            .. "de capture: "
            .. tostring(capture_error)
      )
   end

   local execution_command = build_timeout_command(
      command,
      timeout_seconds,
      kill_after_seconds
   )

   local captured_command = build_captured_command(
      execution_command,
      stdout_path,
      stderr_path
   )

   local call_ok, ok, reason, code = pcall(
      os.execute,
      captured_command
   )

   if not call_ok then
      local cleanup_ok, cleanup_error =
         cleanup_capture_paths(
            stdout_path,
            stderr_path
         )

      local message =
         "échec interne pendant l'exécution: "
            .. tostring(ok)

      if not cleanup_ok then
         message = append_detail(
            message,
            "nettoyage impossible: "
               .. tostring(cleanup_error)
         )
      end

      return create_internal_error_result(
         command,
         message,
         {
            timeout_seconds = timeout_seconds,
            kill_after_seconds =
               kill_after_seconds,
         }
      )
   end

   local exit_code = normalize_exit_code(
      ok,
      reason,
      code
   )

   local timed_out = resolve_timed_out(
      exit_code,
      timeout_seconds
   )

   local interrupted = resolve_interrupted(
      reason,
      exit_code,
      timed_out
   )

   local stdout, stdout_error = read_capture(stdout_path)
   local stderr, stderr_error = read_capture(stderr_path)

   local cleanup_ok, cleanup_error =
      cleanup_capture_paths(
         stdout_path,
         stderr_path
      )

   local read_errors = {}

   if stdout == nil then
      table.insert(
         read_errors,
         "impossible de lire stdout: "
            .. tostring(stdout_error)
      )
   end

   if stderr == nil then
      table.insert(
         read_errors,
         "impossible de lire stderr: "
            .. tostring(stderr_error)
      )
   end

   if #read_errors > 0 then
      local message = table.concat(read_errors, "; ")

      if not cleanup_ok then
         message = append_detail(
            message,
            "nettoyage impossible: "
               .. tostring(cleanup_error)
         )
      end

      return create_internal_error_result(
         command,
         message,
         {
            executed = true,
            exit_code = exit_code,
            reason = reason,
            stdout = stdout,
            stderr = stderr,
            timed_out = timed_out,
            interrupted = interrupted,
            timeout_seconds = timeout_seconds,
            kill_after_seconds =
               kill_after_seconds,
         }
      )
   end

   if not cleanup_ok then
      return create_internal_error_result(
         command,
         "impossible de nettoyer les fichiers "
            .. "temporaires de capture: "
            .. tostring(cleanup_error),
         {
            executed = true,
            exit_code = exit_code,
            reason = reason,
            stdout = stdout,
            stderr = stderr,
            timed_out = timed_out,
            interrupted = interrupted,
            timeout_seconds = timeout_seconds,
            kill_after_seconds =
               kill_after_seconds,
         }
      )
   end

   return {
      ok = exit_code == 0,
      command = command,
      executed = true,
      exit_code = exit_code,
      reason = reason,
      stdout = stdout,
      stderr = stderr,
      timed_out = timed_out,
      interrupted = interrupted,
      timeout_seconds = timeout_seconds,
      kill_after_seconds = kill_after_seconds,
      error = resolve_error(
         exit_code,
         timed_out,
         interrupted
      ),
   }
end

return SystemExecutor
