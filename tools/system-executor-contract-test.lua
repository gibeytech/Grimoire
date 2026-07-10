package.path = "./?.lua;./?/init.lua;" .. package.path

local SystemExecutor = require("installer.system_executor")

print("== SystemExecutor RC3-A1 Contract Test ==")

local function shell_quote(value)
   local string_value = tostring(value)

   return "'" .. string_value:gsub("'", "'\\''") .. "'"
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
-- Commande invalide
----------------------------------------------------------------------

local invalid_result = SystemExecutor.execute(nil)

assert_normalized_result(invalid_result, nil)
assert(invalid_result.ok == false)
assert(invalid_result.executed == false)
assert(invalid_result.exit_code == nil)
assert(invalid_result.reason == nil)
assert(invalid_result.stdout == "")
assert(invalid_result.stderr == "")
assert(invalid_result.error == "Commande système invalide")

----------------------------------------------------------------------
-- Succès sans sortie
----------------------------------------------------------------------

local success_without_output = SystemExecutor.execute("true")

assert_normalized_result(success_without_output, "true")
assert(success_without_output.ok == true)
assert(success_without_output.executed == true)
assert(success_without_output.exit_code == 0)
assert(success_without_output.reason == "exit")
assert(success_without_output.stdout == "")
assert(success_without_output.stderr == "")
assert(success_without_output.error == nil)

----------------------------------------------------------------------
-- Succès avec stdout
----------------------------------------------------------------------

local stdout_command =
   "printf '%s' 'sortie standard contrôlée'"

local stdout_result = SystemExecutor.execute(stdout_command)

assert_normalized_result(stdout_result, stdout_command)
assert(stdout_result.ok == true)
assert(stdout_result.executed == true)
assert(stdout_result.exit_code == 0)
assert(stdout_result.reason == "exit")
assert(stdout_result.stdout == "sortie standard contrôlée")
assert(stdout_result.stderr == "")
assert(stdout_result.error == nil)

----------------------------------------------------------------------
-- Succès avec stderr
----------------------------------------------------------------------

local stderr_command =
   "printf '%s' 'avertissement contrôlé' >&2"

local stderr_result = SystemExecutor.execute(stderr_command)

assert_normalized_result(stderr_result, stderr_command)
assert(stderr_result.ok == true)
assert(stderr_result.executed == true)
assert(stderr_result.exit_code == 0)
assert(stderr_result.reason == "exit")
assert(stderr_result.stdout == "")
assert(stderr_result.stderr == "avertissement contrôlé")
assert(stderr_result.error == nil)

----------------------------------------------------------------------
-- Échec avec stdout, stderr et code de sortie explicite
----------------------------------------------------------------------

local failure_command = table.concat({
   "printf '%s' 'sortie avant échec';",
   "printf '%s' 'erreur contrôlée' >&2;",
   "exit 7",
}, " ")

local failure_result = SystemExecutor.execute(failure_command)

assert_normalized_result(failure_result, failure_command)
assert(failure_result.ok == false)
assert(failure_result.executed == true)
assert(failure_result.exit_code == 7)
assert(failure_result.reason == "exit")
assert(failure_result.stdout == "sortie avant échec")
assert(failure_result.stderr == "erreur contrôlée")
assert(failure_result.error == "Commande système échouée")

----------------------------------------------------------------------
-- Chemin contenant des espaces
----------------------------------------------------------------------

local temporary_base = os.tmpname()

assert(type(temporary_base) == "string")
assert(temporary_base:match("^/tmp/") ~= nil)

os.remove(temporary_base)

local path_with_spaces =
   temporary_base .. " chemin avec espaces.txt"

local expected_content = "contenu avec espaces"

local path_command = table.concat({
   "printf '%s'",
   shell_quote(expected_content),
   ">",
   shell_quote(path_with_spaces),
   "&&",
   "cat",
   shell_quote(path_with_spaces),
}, " ")

local path_result = SystemExecutor.execute(path_command)

os.remove(path_with_spaces)

assert_normalized_result(path_result, path_command)
assert(path_result.ok == true)
assert(path_result.executed == true)
assert(path_result.exit_code == 0)
assert(path_result.stdout == expected_content)
assert(path_result.stderr == "")
assert(path_result.error == nil)

----------------------------------------------------------------------
-- Nettoyage des fichiers temporaires de capture
----------------------------------------------------------------------

local cleanup_stdout_path = os.tmpname()
local cleanup_stderr_path = os.tmpname()

assert(cleanup_stdout_path:match("^/tmp/") ~= nil)
assert(cleanup_stderr_path:match("^/tmp/") ~= nil)

os.remove(cleanup_stdout_path)
os.remove(cleanup_stderr_path)

local original_tmpname = os.tmpname
local temporary_call_count = 0

os.tmpname = function()
   temporary_call_count = temporary_call_count + 1

   if temporary_call_count == 1 then
      return cleanup_stdout_path
   end

   if temporary_call_count == 2 then
      return cleanup_stderr_path
   end

   error("Appel temporaire inattendu")
end

local cleanup_result = SystemExecutor.execute(
   "printf '%s' 'nettoyage contrôlé'"
)

os.tmpname = original_tmpname

assert_normalized_result(
   cleanup_result,
   "printf '%s' 'nettoyage contrôlé'"
)

assert(cleanup_result.ok == true)
assert(cleanup_result.stdout == "nettoyage contrôlé")

local remaining_stdout_file = io.open(
   cleanup_stdout_path,
   "rb"
)

local remaining_stderr_file = io.open(
   cleanup_stderr_path,
   "rb"
)

if remaining_stdout_file then
   remaining_stdout_file:close()
end

if remaining_stderr_file then
   remaining_stderr_file:close()
end

assert(remaining_stdout_file == nil)
assert(remaining_stderr_file == nil)

----------------------------------------------------------------------
-- Erreur interne du moteur
----------------------------------------------------------------------

local real_tmpname = os.tmpname

os.tmpname = function()
   error("Échec temporaire simulé")
end

local internal_error_result = SystemExecutor.execute("true")

os.tmpname = real_tmpname

assert_normalized_result(internal_error_result, "true")
assert(internal_error_result.ok == false)
assert(internal_error_result.executed == false)
assert(internal_error_result.exit_code == nil)
assert(internal_error_result.reason == nil)
assert(internal_error_result.stdout == "")
assert(internal_error_result.stderr == "")

assert(
   internal_error_result.error:match(
      "^Erreur interne SystemExecutor:"
   ) ~= nil
)

print("")
print(
   "RC3-A1 OK : SystemExecutor retourne un résultat système enrichi."
)
