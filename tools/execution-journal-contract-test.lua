package.path = "./?.lua;./?/init.lua;" .. package.path

local ExecutionPlan = require(
   "installer.model.execution_plan"
)

local Executor = require("installer.executor")

print("== ExecutionJournal RC3-A3 Contract Test ==")

local function assert_common_entry(
   entry,
   expected
)
   assert(type(entry) == "table")
   assert(entry.sequence == expected.sequence)
   assert(entry.total == expected.total)
   assert(entry.type == expected.type)
   assert(entry.manager == expected.manager)
   assert(entry.name == expected.name)
   assert(entry.mode == expected.mode)
   assert(entry.ok == expected.ok)
   assert(type(entry.prepared) == "boolean")
   assert(type(entry.simulated) == "boolean")
   assert(type(entry.executed) == "boolean")

   assert(
      entry.command == nil
         or type(entry.command) == "string"
   )

   assert(
      entry.exit_code == nil
         or type(entry.exit_code) == "number"
   )

   assert(
      entry.reason == nil
         or type(entry.reason) == "string"
   )

   assert(type(entry.stdout) == "string")
   assert(type(entry.stderr) == "string")

   assert(
      entry.error == nil
         or type(entry.error) == "string"
   )
end

----------------------------------------------------------------------
-- Journal dry-run pour tous les types d'action
----------------------------------------------------------------------

local dry_run_plan = ExecutionPlan:new({
   profile = {
      id = "journal-dry-run",
      name = "Journal Dry Run",
   },
   mode = "dry-run",
   actions = {
      {
         type = "command",
         manager = "packages",
         name = "journal-command",
         command = "printf '%s' 'non exécuté'",
      },
      {
         type = "file_operation",
         manager = "assets",
         name = "journal-directory",
         operation = {
            type = "mkdir",
            destination =
               "/tmp/grimoire journal dry run",
         },
      },
      {
         type = "service_operation",
         manager = "services",
         name = "journal-service",
         service = "NetworkManager",
         operation = "enable",
      },
      {
         type = "shell_operation",
         manager = "shell",
         name = "journal-shell",
         module = "hub",
         runtime = "grimoire-shell",
      },
   },
})

local dry_run_result = Executor.execute(
   dry_run_plan,
   {
      dry_run = true,
   }
)

assert(dry_run_result.ok == true)
assert(dry_run_result.mode == "dry-run")
assert(type(dry_run_result.results) == "table")
assert(#dry_run_result.results == 4)
assert(type(dry_run_result.journal) == "table")
assert(#dry_run_result.journal == 4)

local expected_dry_run_entries = {
   {
      sequence = 1,
      total = 4,
      type = "command",
      manager = "packages",
      name = "journal-command",
      mode = "dry-run",
      ok = true,
   },
   {
      sequence = 2,
      total = 4,
      type = "file_operation",
      manager = "assets",
      name = "journal-directory",
      mode = "dry-run",
      ok = true,
   },
   {
      sequence = 3,
      total = 4,
      type = "service_operation",
      manager = "services",
      name = "journal-service",
      mode = "dry-run",
      ok = true,
   },
   {
      sequence = 4,
      total = 4,
      type = "shell_operation",
      manager = "shell",
      name = "journal-shell",
      mode = "dry-run",
      ok = true,
      reason = "dry-run",
   },
}

for index, expected in ipairs(
   expected_dry_run_entries
) do
   local entry = dry_run_result.journal[index]

   assert_common_entry(entry, expected)
   assert(entry.prepared == true)
   assert(entry.simulated == true)
   assert(entry.executed == false)
   assert(entry.exit_code == nil)
   assert(entry.reason == expected.reason)
   assert(entry.stdout == "")
   assert(entry.stderr == "")
   assert(entry.error == nil)
end

assert(
   dry_run_result.journal[1].command
      == "printf '%s' 'non exécuté'"
)

assert(
   type(dry_run_result.journal[2].command)
      == "string"
)

assert(
   type(dry_run_result.journal[3].command)
      == "string"
)

assert(
   dry_run_result.journal[3].command:find(
      "systemctl",
      1,
      true
   ) ~= nil
)

assert(
   dry_run_result.journal[3].command:find(
      "enable",
      1,
      true
   ) ~= nil
)

assert(dry_run_result.journal[4].command == nil)

----------------------------------------------------------------------
-- Journal apply-real avec stdout et stderr
----------------------------------------------------------------------

local apply_real_command = table.concat({
   "printf '%s' 'journal stdout';",
   "printf '%s' 'journal stderr' >&2",
}, " ")

local temporary_directory = os.tmpname()

assert(type(temporary_directory) == "string")
assert(temporary_directory:match("^/tmp/") ~= nil)

os.remove(temporary_directory)

temporary_directory =
   temporary_directory .. " journal directory"

local apply_real_plan = ExecutionPlan:new({
   profile = {
      id = "journal-apply-real",
      name = "Journal Apply Real",
   },
   mode = "apply-real",
   actions = {
      {
         type = "command",
         manager = "packages",
         name = "captured-command",
         command = apply_real_command,
      },
      {
         type = "file_operation",
         manager = "assets",
         name = "captured-directory",
         operation = {
            type = "mkdir",
            destination = temporary_directory,
         },
      },
   },
})

local apply_real_result = Executor.execute(
   apply_real_plan,
   {
      dry_run = false,
      apply_real = true,
   }
)

os.remove(temporary_directory)

assert(apply_real_result.ok == true)
assert(apply_real_result.mode == "apply-real")
assert(apply_real_result.executed_actions == 2)
assert(#apply_real_result.results == 2)
assert(#apply_real_result.journal == 2)

local command_entry = apply_real_result.journal[1]

assert_common_entry(command_entry, {
   sequence = 1,
   total = 2,
   type = "command",
   manager = "packages",
   name = "captured-command",
   mode = "apply-real",
   ok = true,
})

assert(command_entry.prepared == true)
assert(command_entry.simulated == false)
assert(command_entry.executed == true)
assert(command_entry.command == apply_real_command)
assert(command_entry.exit_code == 0)
assert(command_entry.reason == "exit")
assert(command_entry.stdout == "journal stdout")
assert(command_entry.stderr == "journal stderr")
assert(command_entry.error == nil)

local directory_entry = apply_real_result.journal[2]

assert_common_entry(directory_entry, {
   sequence = 2,
   total = 2,
   type = "file_operation",
   manager = "assets",
   name = "captured-directory",
   mode = "apply-real",
   ok = true,
})

assert(directory_entry.prepared == true)
assert(directory_entry.simulated == false)
assert(directory_entry.executed == true)
assert(type(directory_entry.command) == "string")
assert(directory_entry.exit_code == 0)
assert(directory_entry.reason == "exit")
assert(directory_entry.stdout == "")
assert(directory_entry.stderr == "")
assert(directory_entry.error == nil)

----------------------------------------------------------------------
-- Journal partiel en cas d'arrêt sur erreur
----------------------------------------------------------------------

local failure_plan = ExecutionPlan:new({
   profile = {
      id = "journal-failure",
      name = "Journal Failure",
   },
   mode = "dry-run",
   actions = {
      {
         type = "command",
         manager = "packages",
         name = "valid-command",
         command = "echo valid",
      },
      {
         type = "unknown_action",
         manager = "services",
         name = "invalid-action",
      },
      {
         type = "command",
         manager = "packages",
         name = "never-dispatched",
         command = "echo never",
      },
   },
})

local failure_result = Executor.execute(
   failure_plan,
   {
      dry_run = true,
   }
)

assert(failure_result.ok == false)
assert(failure_result.failed_at == "services")
assert(#failure_result.results == 2)
assert(type(failure_result.journal) == "table")
assert(#failure_result.journal == 2)

local successful_entry = failure_result.journal[1]

assert_common_entry(successful_entry, {
   sequence = 1,
   total = 3,
   type = "command",
   manager = "packages",
   name = "valid-command",
   mode = "dry-run",
   ok = true,
})

assert(successful_entry.prepared == true)
assert(successful_entry.simulated == true)
assert(successful_entry.executed == false)
assert(successful_entry.error == nil)

local failed_entry = failure_result.journal[2]

assert_common_entry(failed_entry, {
   sequence = 2,
   total = 3,
   type = "unknown_action",
   manager = "services",
   name = "invalid-action",
   mode = "dry-run",
   ok = false,
})

assert(failed_entry.prepared == false)
assert(failed_entry.simulated == false)
assert(failed_entry.executed == false)
assert(failed_entry.command == nil)
assert(failed_entry.exit_code == nil)
assert(failed_entry.reason == nil)
assert(failed_entry.stdout == "")
assert(failed_entry.stderr == "")

assert(
   failed_entry.error
      == "Type d'action inconnu: unknown_action"
)

----------------------------------------------------------------------
-- ExecutionPlan invalide
----------------------------------------------------------------------

local invalid_plan_result = Executor.execute(
   nil,
   {
      dry_run = true,
   }
)

assert(invalid_plan_result.ok == false)
assert(invalid_plan_result.failed_at == "executor")
assert(type(invalid_plan_result.results) == "table")
assert(#invalid_plan_result.results == 0)
assert(type(invalid_plan_result.journal) == "table")
assert(#invalid_plan_result.journal == 0)

print("")
print(
   "RC3-A3 OK : Executor expose un journal "
      .. "d'exécution structuré."
)
