package.path = "./?.lua;./?/init.lua;"
   .. package.path

local ExecutionPlan = require(
   "installer.model.execution_plan"
)

local Executor = require(
   "installer.executor"
)

local ExecutionTransaction = require(
   "installer.execution_transaction"
)

local FilesystemRollback = require(
   "installer.filesystem_rollback"
)

print("== ExecutionTransaction RC3-B3 Contract Test ==")

local function shell_quote(value)
   local string_value = tostring(value)

   return "'" .. string_value:gsub(
      "'",
      "'\\''"
   ) .. "'"
end

local function command_succeeded(command)
   local ok, _, code = os.execute(command)

   return ok == true
      or ok == 0
      or code == 0
end

local function path_exists(path)
   return command_succeeded(
      "test -e "
         .. shell_quote(path)
         .. " || test -L "
         .. shell_quote(path)
   )
end

local function directory_exists(path)
   return command_succeeded(
      "test -d " .. shell_quote(path)
   )
end

local function write_file(path, content)
   local file, open_error = io.open(path, "wb")

   assert(
      file,
      "Impossible d'écrire "
         .. tostring(path)
         .. ": "
         .. tostring(open_error)
   )

   local written, write_error =
      file:write(content)

   assert(
      written,
      "Écriture impossible: "
         .. tostring(write_error)
   )

   file:close()
end

local function ready_metadata(destination)
   return {
      kind = "filesystem",
      status = "ready",
      eligible = true,
      reversible = true,
      compensation_type =
         "remove-created-path",
      operation_type = "copy",
      source = "/tmp/source",
      destination = destination,
      overwrite = false,
      created_destination = true,
      destination_existed_before = false,
      previous_destination = nil,
      reason = nil,
   }
end

local function assert_rollback_contract(rollback)
   assert(type(rollback) == "table")
   assert(type(rollback.attempted) == "boolean")
   assert(type(rollback.ok) == "boolean")
   assert(type(rollback.status) == "string")
   assert(type(rollback.mode) == "string")
   assert(type(rollback.total_actions) == "number")
   assert(type(rollback.successful_actions) == "number")
   assert(type(rollback.failed_actions) == "number")
   assert(type(rollback.executed_actions) == "number")
   assert(type(rollback.results) == "table")

   assert(
      rollback.error == nil
         or type(rollback.error) == "string"
   )
end

local temporary_directory = os.tmpname()

assert(type(temporary_directory) == "string")
assert(temporary_directory:match("^/tmp/") ~= nil)

os.remove(temporary_directory)

assert(
   command_succeeded(
      "mkdir -p -- "
         .. shell_quote(temporary_directory)
   )
)

local test_ok, test_error = xpcall(
   function()
      local source_path =
         temporary_directory
            .. "/transaction source.txt"

      local committed_destination =
         temporary_directory
            .. "/committed destination.txt"

      local rollback_copy_destination =
         temporary_directory
            .. "/rollback copy.txt"

      local rollback_directory =
         temporary_directory
            .. "/non reversible directory"

      local rollback_symlink_destination =
         temporary_directory
            .. "/rollback symlink.txt"

      local dry_run_destination =
         temporary_directory
            .. "/dry run destination.txt"

      write_file(
         source_path,
         "contenu transactionnel\n"
      )

      ---------------------------------------------------------------
      -- Transaction validée sans rollback
      ---------------------------------------------------------------

      local committed_plan =
         ExecutionPlan:new({
            profile = {
               id = "transaction-committed",
               name = "Transaction Committed",
            },
            mode = "apply-real",
            actions = {
               {
                  type = "file_operation",
                  manager = "assets",
                  name = "committed-copy",
                  operation = {
                     type = "copy",
                     source = source_path,
                     destination =
                        committed_destination,
                     overwrite = false,
                  },
               },
            },
         })

      local committed_result =
         Executor.execute(
            committed_plan,
            {
               dry_run = false,
               apply_real = true,
            }
         )

      assert(committed_result.ok == true)
      assert(
         committed_result.transaction_status
            == "committed"
      )
      assert(committed_result.executed_actions == 1)
      assert(path_exists(committed_destination))

      assert_rollback_contract(
         committed_result.rollback
      )

      assert(
         committed_result.rollback.attempted
            == false
      )

      assert(
         committed_result.rollback.status
            == "not-required"
      )

      assert(
         committed_result.rollback.total_actions
            == 0
      )

      ---------------------------------------------------------------
      -- Échec apply-real et rollback automatique
      ---------------------------------------------------------------

      local failure_plan =
         ExecutionPlan:new({
            profile = {
               id = "transaction-failure",
               name = "Transaction Failure",
            },
            mode = "apply-real",
            actions = {
               {
                  type = "file_operation",
                  manager = "assets",
                  name = "rollback-copy",
                  operation = {
                     type = "copy",
                     source = source_path,
                     destination =
                        rollback_copy_destination,
                     overwrite = false,
                  },
               },
               {
                  type = "file_operation",
                  manager = "assets",
                  name = "non-reversible-mkdir",
                  operation = {
                     type = "mkdir",
                     destination =
                        rollback_directory,
                  },
               },
               {
                  type = "file_operation",
                  manager = "deploy",
                  name = "rollback-symlink",
                  operation = {
                     type = "symlink",
                     source = source_path,
                     destination =
                        rollback_symlink_destination,
                     overwrite = false,
                  },
               },
               {
                  type = "command",
                  manager = "packages",
                  name = "transaction-failure",
                  command = "false",
               },
            },
         })

      local failure_result =
         Executor.execute(
            failure_plan,
            {
               dry_run = false,
               apply_real = true,
            }
         )

      assert(failure_result.ok == false)

      assert(
         failure_result.transaction_status
            == "rolled-back"
      )

      assert(failure_result.failed_at == "packages")
      assert(failure_result.executed_actions == 4)
      assert(#failure_result.results == 4)
      assert(#failure_result.journal == 4)

      assert_rollback_contract(
         failure_result.rollback
      )

      assert(
         failure_result.rollback.attempted
            == true
      )

      assert(failure_result.rollback.ok == true)

      assert(
         failure_result.rollback.status
            == "completed"
      )

      assert(
         failure_result.rollback.total_actions
            == 2
      )

      assert(
         failure_result.rollback.successful_actions
            == 2
      )

      assert(
         failure_result.rollback.failed_actions
            == 0
      )

      assert(
         failure_result.rollback.executed_actions
            == 2
      )

      assert(
         #failure_result.rollback.results
            == 2
      )

      local first_rollback =
         failure_result.rollback.results[1]

      local second_rollback =
         failure_result.rollback.results[2]

      assert(first_rollback.rollback_sequence == 1)
      assert(first_rollback.original_sequence == 3)
      assert(first_rollback.manager == "deploy")
      assert(first_rollback.name == "rollback-symlink")
      assert(first_rollback.ok == true)
      assert(first_rollback.status == "removed")

      assert(
         first_rollback
            .compensation
            .destination
            == rollback_symlink_destination
      )

      assert(
         first_rollback.result.status
            == "removed"
      )

      assert(second_rollback.rollback_sequence == 2)
      assert(second_rollback.original_sequence == 1)
      assert(second_rollback.manager == "assets")
      assert(second_rollback.name == "rollback-copy")
      assert(second_rollback.ok == true)
      assert(second_rollback.status == "removed")

      assert(
         second_rollback
            .compensation
            .destination
            == rollback_copy_destination
      )

      assert(
         path_exists(
            rollback_symlink_destination
         ) == false
      )

      assert(
         path_exists(
            rollback_copy_destination
         ) == false
      )

      assert(path_exists(source_path) == true)

      assert(
         directory_exists(
            rollback_directory
         ) == true
      )

      assert(
         failure_result
            .journal[1]
            .compensation
            .status
            == "ready"
      )

      assert(
         failure_result
            .journal[2]
            .compensation
            .status
            == "unsupported"
      )

      assert(
         failure_result
            .journal[3]
            .compensation
            .status
            == "ready"
      )

      assert(
         failure_result
            .journal[4]
            .compensation
            == nil
      )

      ---------------------------------------------------------------
      -- Échec dry-run : aucun rollback réel
      ---------------------------------------------------------------

      local dry_run_plan =
         ExecutionPlan:new({
            profile = {
               id = "transaction-dry-run",
               name = "Transaction Dry Run",
            },
            mode = "dry-run",
            actions = {
               {
                  type = "file_operation",
                  manager = "assets",
                  name = "dry-run-copy",
                  operation = {
                     type = "copy",
                     source = source_path,
                     destination =
                        dry_run_destination,
                     overwrite = false,
                  },
               },
               {
                  type = "unknown-action",
                  manager = "services",
                  name = "dry-run-failure",
               },
            },
         })

      local dry_run_result =
         Executor.execute(
            dry_run_plan,
            {
               dry_run = true,
            }
         )

      assert(dry_run_result.ok == false)

      assert(
         dry_run_result.transaction_status
            == "failed"
      )

      assert(dry_run_result.executed_actions == 0)

      assert_rollback_contract(
         dry_run_result.rollback
      )

      assert(
         dry_run_result.rollback.attempted
            == false
      )

      assert(
         dry_run_result.rollback.status
            == "not-applicable"
      )

      assert(
         dry_run_result.rollback.total_actions
            == 0
      )

      assert(
         path_exists(dry_run_destination)
            == false
      )

      ---------------------------------------------------------------
      -- Un échec de rollback n'arrête pas les suivants
      ---------------------------------------------------------------

      local transaction =
         ExecutionTransaction.new({
            mode = "apply-real",
         })

      local first_destination =
         temporary_directory
            .. "/first mocked rollback"

      local second_destination =
         temporary_directory
            .. "/second mocked rollback"

      assert(
         transaction:register({
            sequence = 1,
            total = 2,
            type = "file_operation",
            manager = "assets",
            name = "first-compensation",
            ok = true,
            executed = true,
            compensation =
               ready_metadata(
                  first_destination
               ),
         }) == true
      )

      assert(
         transaction:register({
            sequence = 2,
            total = 2,
            type = "file_operation",
            manager = "deploy",
            name = "second-compensation",
            ok = true,
            executed = true,
            compensation =
               ready_metadata(
                  second_destination
               ),
         }) == true
      )

      assert(transaction:count() == 2)

      local original_run =
         FilesystemRollback.run

      local calls = {}

      local rollback_call_ok,
         rollback_or_error = xpcall(
         function()
            FilesystemRollback.run =
               function(metadata)
                  table.insert(
                     calls,
                     metadata.destination
                  )

                  if metadata.destination
                     == second_destination
                  then
                     error(
                        "Échec simulé du rollback"
                     )
                  end

                  return {
                     ok = true,
                     mode = "apply-real",
                     status = "removed",
                     metadata = metadata,
                     compensation_type =
                        metadata.compensation_type,
                     destination =
                        metadata.destination,
                     command = "mocked",
                     prepared = true,
                     simulated = false,
                     executed = true,
                     removed = true,
                     already_absent = false,
                     exit_code = 0,
                     reason = "exit",
                     stdout = "",
                     stderr = "",
                     system_result = {},
                     error = nil,
                  }
               end

            return transaction:rollback()
         end,
         debug.traceback
      )

      FilesystemRollback.run = original_run

      assert(
         rollback_call_ok,
         rollback_or_error
      )

      local partial_rollback =
         rollback_or_error

      assert_rollback_contract(
         partial_rollback
      )

      assert(partial_rollback.attempted == true)
      assert(partial_rollback.ok == false)
      assert(partial_rollback.status == "failed")
      assert(partial_rollback.total_actions == 2)
      assert(partial_rollback.successful_actions == 1)
      assert(partial_rollback.failed_actions == 1)
      assert(partial_rollback.executed_actions == 1)
      assert(#partial_rollback.results == 2)

      assert(#calls == 2)
      assert(calls[1] == second_destination)
      assert(calls[2] == first_destination)

      assert(
         partial_rollback
            .results[1]
            .original_sequence
            == 2
      )

      assert(
         partial_rollback
            .results[1]
            .ok
            == false
      )

      assert(
         partial_rollback
            .results[1]
            .result
            .error
            :find(
               "Erreur interne pendant le rollback",
               1,
               true
            ) ~= nil
      )

      assert(
         partial_rollback
            .results[2]
            .original_sequence
            == 1
      )

      assert(
         partial_rollback
            .results[2]
            .ok
            == true
      )
   end,
   debug.traceback
)

local cleanup_ok, cleanup_error = pcall(
   function()
      assert(
         temporary_directory:match("^/tmp/")
            ~= nil
      )

      assert(
         command_succeeded(
            "rm -rf -- "
               .. shell_quote(
                  temporary_directory
               )
         )
      )
   end
)

if not cleanup_ok then
   error(
      "Échec du nettoyage du bac à sable RC3-B3:\n"
         .. tostring(cleanup_error)
   )
end

if not test_ok then
   error(test_error)
end

assert(path_exists(temporary_directory) == false)

print("")
print(
   "RC3-B3 OK : Executor annule les compensations "
      .. "réversibles dans l'ordre inverse après un échec."
)
