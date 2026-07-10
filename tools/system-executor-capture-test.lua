package.path = "./?.lua;./?/init.lua;" .. package.path

local SystemExecutor = require("installer.system_executor")

print("== SystemExecutor RC3-A2 Capture Test ==")

local function shell_quote(value)
   local string_value = tostring(value)

   return "'" .. string_value:gsub("'", "'\\''") .. "'"
end

local function path_exists(path)
   local file = io.open(path, "rb")

   if not file then
      return false
   end

   file:close()

   return true
end

local function reserve_capture_paths()
   local stdout_path = os.tmpname()
   local stderr_path = os.tmpname()

   assert(type(stdout_path) == "string")
   assert(type(stderr_path) == "string")
   assert(stdout_path:match("^/tmp/") ~= nil)
   assert(stderr_path:match("^/tmp/") ~= nil)
   assert(stdout_path ~= stderr_path)

   os.remove(stdout_path)
   os.remove(stderr_path)

   return stdout_path, stderr_path
end

local function with_os_overrides(overrides, callback)
   local originals = {}

   for name, value in pairs(overrides) do
      originals[name] = os[name]
      os[name] = value
   end

   local packed_result

   local call_ok, call_error = xpcall(
      function()
         packed_result = table.pack(callback())
      end,
      debug.traceback
   )

   for name, value in pairs(originals) do
      os[name] = value
   end

   if not call_ok then
      error(call_error, 0)
   end

   return table.unpack(
      packed_result,
      1,
      packed_result.n
   )
end

local function create_sequential_tmpname(
   stdout_path,
   stderr_path
)
   local call_count = 0

   return function()
      call_count = call_count + 1

      if call_count == 1 then
         return stdout_path
      end

      if call_count == 2 then
         return stderr_path
      end

      error("Appel os.tmpname inattendu")
   end
end

local function assert_normalized_result(result, command)
   assert(type(result) == "table")
   assert(type(result.ok) == "boolean")
   assert(result.command == command)
   assert(type(result.executed) == "boolean")

   assert(
      result.exit_code == nil
         or type(result.exit_code) == "number"
   )

   assert(
      result.reason == nil
         or type(result.reason) == "string"
   )

   assert(type(result.stdout) == "string")
   assert(type(result.stderr) == "string")

   assert(
      result.error == nil
         or type(result.error) == "string"
   )
end

----------------------------------------------------------------------
-- Conservation exacte des sorties multilignes
----------------------------------------------------------------------

local multiline_command = table.concat({
   "printf 'stdout ligne 1\\nstdout ligne 2\\n'",
   "printf 'stderr ligne 1\\nstderr ligne 2\\n' >&2",
}, "\n")

local multiline_result = SystemExecutor.execute(
   multiline_command
)

assert_normalized_result(
   multiline_result,
   multiline_command
)

assert(multiline_result.ok == true)
assert(multiline_result.executed == true)
assert(multiline_result.exit_code == 0)
assert(multiline_result.reason == "exit")

assert(
   multiline_result.stdout
      == "stdout ligne 1\nstdout ligne 2\n"
)

assert(
   multiline_result.stderr
      == "stderr ligne 1\nstderr ligne 2\n"
)

assert(multiline_result.error == nil)

----------------------------------------------------------------------
-- Redirections internes et chemin contenant des espaces
----------------------------------------------------------------------

local redirected_base = os.tmpname()

assert(type(redirected_base) == "string")
assert(redirected_base:match("^/tmp/") ~= nil)

os.remove(redirected_base)

local redirected_path =
   redirected_base .. " redirection interne.txt"

local redirected_command = table.concat({
   "printf '%s\\n' 'alpha' 'beta' >",
   shell_quote(redirected_path),
   ";",
   "sed 's/^/capturé:/'",
   shell_quote(redirected_path),
   ";",
   "printf '%s' 'stderr interne' >&2",
}, " ")

local redirected_result = SystemExecutor.execute(
   redirected_command
)

os.remove(redirected_path)

assert_normalized_result(
   redirected_result,
   redirected_command
)

assert(redirected_result.ok == true)
assert(redirected_result.executed == true)
assert(redirected_result.exit_code == 0)

assert(
   redirected_result.stdout
      == "capturé:alpha\ncapturé:beta\n"
)

assert(redirected_result.stderr == "stderr interne")
assert(redirected_result.error == nil)

----------------------------------------------------------------------
-- Sorties volumineuses sur stdout et stderr
----------------------------------------------------------------------

local large_output_size = 131072

local large_output_command = table.concat({
   "awk 'BEGIN {",
   "for (i = 0; i <",
   tostring(large_output_size),
   '; i++) printf "o"',
   "}'",
   ";",
   "awk 'BEGIN {",
   "for (i = 0; i <",
   tostring(large_output_size),
   '; i++) printf "e"',
   "}' >&2",
}, " ")

local large_output_result = SystemExecutor.execute(
   large_output_command
)

assert_normalized_result(
   large_output_result,
   large_output_command
)

assert(large_output_result.ok == true)
assert(large_output_result.executed == true)
assert(large_output_result.exit_code == 0)
assert(#large_output_result.stdout == large_output_size)
assert(#large_output_result.stderr == large_output_size)

assert(
   large_output_result.stdout:find("[^o]") == nil
)

assert(
   large_output_result.stderr:find("[^e]") == nil
)

assert(large_output_result.error == nil)

----------------------------------------------------------------------
-- Isolation entre deux exécutions successives
----------------------------------------------------------------------

local first_command = "printf '%s' 'première sortie'"

local first_result = SystemExecutor.execute(first_command)

local second_command =
   "printf '%s' 'deuxième erreur' >&2"

local second_result = SystemExecutor.execute(second_command)

assert_normalized_result(first_result, first_command)
assert_normalized_result(second_result, second_command)

assert(first_result.ok == true)
assert(first_result.stdout == "première sortie")
assert(first_result.stderr == "")

assert(second_result.ok == true)
assert(second_result.stdout == "")
assert(second_result.stderr == "deuxième erreur")

----------------------------------------------------------------------
-- Collision entre les deux chemins temporaires
----------------------------------------------------------------------

local collision_path = os.tmpname()

assert(type(collision_path) == "string")
assert(collision_path:match("^/tmp/") ~= nil)

os.remove(collision_path)

local collision_result = with_os_overrides(
   {
      tmpname = function()
         return collision_path
      end,
   },
   function()
      return SystemExecutor.execute("true")
   end
)

assert_normalized_result(collision_result, "true")
assert(collision_result.ok == false)
assert(collision_result.executed == false)
assert(collision_result.exit_code == nil)
assert(collision_result.stdout == "")
assert(collision_result.stderr == "")

assert(
   collision_result.error:find(
      "Les chemins de capture sont identiques",
      1,
      true
   ) ~= nil
)

assert(path_exists(collision_path) == false)

----------------------------------------------------------------------
-- Nettoyage après une erreur interne de os.execute
----------------------------------------------------------------------

local internal_stdout_path, internal_stderr_path =
   reserve_capture_paths()

local internal_result = with_os_overrides(
   {
      tmpname = create_sequential_tmpname(
         internal_stdout_path,
         internal_stderr_path
      ),

      execute = function()
         error("Échec os.execute simulé")
      end,
   },
   function()
      return SystemExecutor.execute("true")
   end
)

assert_normalized_result(internal_result, "true")
assert(internal_result.ok == false)
assert(internal_result.executed == false)
assert(internal_result.exit_code == nil)
assert(internal_result.stdout == "")
assert(internal_result.stderr == "")

assert(
   internal_result.error:find(
      "échec interne pendant l'exécution",
      1,
      true
   ) ~= nil
)

assert(path_exists(internal_stdout_path) == false)
assert(path_exists(internal_stderr_path) == false)

----------------------------------------------------------------------
-- Une erreur de nettoyage invalide le résultat moteur
----------------------------------------------------------------------

local cleanup_stdout_path, cleanup_stderr_path =
   reserve_capture_paths()

local real_remove = os.remove

local cleanup_command =
   "printf '%s' 'sortie avant nettoyage'"

local cleanup_failure_result = with_os_overrides(
   {
      tmpname = create_sequential_tmpname(
         cleanup_stdout_path,
         cleanup_stderr_path
      ),

      remove = function(path)
         if path == cleanup_stdout_path then
            return nil, "Suppression simulée"
         end

         return real_remove(path)
      end,
   },
   function()
      return SystemExecutor.execute(cleanup_command)
   end
)

assert_normalized_result(
   cleanup_failure_result,
   cleanup_command
)

assert(cleanup_failure_result.ok == false)
assert(cleanup_failure_result.executed == true)
assert(cleanup_failure_result.exit_code == 0)
assert(cleanup_failure_result.reason == "exit")

assert(
   cleanup_failure_result.stdout
      == "sortie avant nettoyage"
)

assert(cleanup_failure_result.stderr == "")

assert(
   cleanup_failure_result.error:find(
      "impossible de nettoyer les fichiers temporaires",
      1,
      true
   ) ~= nil
)

assert(
   cleanup_failure_result.error:find(
      "stdout",
      1,
      true
   ) ~= nil
)

assert(path_exists(cleanup_stdout_path) == true)
assert(path_exists(cleanup_stderr_path) == false)

real_remove(cleanup_stdout_path)

assert(path_exists(cleanup_stdout_path) == false)

print("")
print(
   "RC3-A2 OK : la capture stdout/stderr est fiable et nettoyée."
)
