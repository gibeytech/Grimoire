local SystemExecutor = {}

local function shell_quote(value)
   local string_value = tostring(value)

   return "'" .. string_value:gsub("'", "'\\''") .. "'"
end

local function normalize_exit_code(ok, reason, code)
   if ok == true then
      return 0
   end

   if type(ok) == "number" then
      return ok
   end

   if type(code) == "number" then
      return code
   end

   return 1
end

local function resolve_error(exit_code)
   if exit_code == 0 then
      return nil
   end

   return "Commande système échouée"
end

local function path_is_in_tmp(path)
   return type(path) == "string"
      and path:match("^/tmp/") ~= nil
end

local function remove_file(path)
   if not path then
      return
   end

   pcall(os.remove, path)
end

local function create_temp_path()
   local call_ok, path_or_error = pcall(os.tmpname)

   if not call_ok then
      return nil, tostring(path_or_error)
   end

   if not path_is_in_tmp(path_or_error) then
      remove_file(path_or_error)

      return nil, "Le chemin temporaire n'est pas situé dans /tmp"
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
      remove_file(stdout_path)

      return nil, nil, stderr_error
   end

   if stdout_path == stderr_path then
      remove_file(stdout_path)

      return nil, nil, "Les chemins de capture sont identiques"
   end

   return stdout_path, stderr_path, nil
end

local function cleanup_capture_paths(stdout_path, stderr_path)
   remove_file(stdout_path)
   remove_file(stderr_path)
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
      return nil, tostring(read_error or "Lecture impossible")
   end

   if not close_ok then
      return nil, tostring(close_result)
   end

   if close_result == nil then
      return nil, tostring(close_error or "Fermeture impossible")
   end

   return content, nil
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
      error = "Erreur interne SystemExecutor: "
         .. tostring(message),
   }
end

local function create_invalid_result(command)
   return {
      ok = false,
      command = command,
      executed = false,
      exit_code = nil,
      reason = nil,
      stdout = "",
      stderr = "",
      error = "Commande système invalide",
   }
end

function SystemExecutor.execute(command)
   if not command or tostring(command) == "" then
      return create_invalid_result(command)
   end

   command = tostring(command)

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

   local captured_command = build_captured_command(
      command,
      stdout_path,
      stderr_path
   )

   local call_ok, ok, reason, code = pcall(
      os.execute,
      captured_command
   )

   if not call_ok then
      cleanup_capture_paths(stdout_path, stderr_path)

      return create_internal_error_result(
         command,
         "échec interne pendant l'exécution: " .. tostring(ok)
      )
   end

   local exit_code = normalize_exit_code(ok, reason, code)

   local stdout, stdout_error = read_capture(stdout_path)
   local stderr, stderr_error = read_capture(stderr_path)

   cleanup_capture_paths(stdout_path, stderr_path)

   if stdout == nil then
      return create_internal_error_result(
         command,
         "impossible de lire stdout: " .. tostring(stdout_error),
         {
            executed = true,
            exit_code = exit_code,
            reason = reason,
            stderr = stderr,
         }
      )
   end

   if stderr == nil then
      return create_internal_error_result(
         command,
         "impossible de lire stderr: " .. tostring(stderr_error),
         {
            executed = true,
            exit_code = exit_code,
            reason = reason,
            stdout = stdout,
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
      error = resolve_error(exit_code),
   }
end

return SystemExecutor
