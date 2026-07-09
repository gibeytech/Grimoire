package.path = "./?.lua;./?/init.lua;" .. package.path

local Executor = require("installer.executor")

print("== Executor RC1-08 Test ==")

local plan = {
    packages = {
        groups = {},
    },
}

local result = Executor.execute(plan, {
    dry_run = true,
})

assert(result.ok == true)
assert(result.dry_run == true)
assert(type(result.results) == "table")
assert(#result.results == 5)

assert(result.results[1].manager == "packages")
assert(result.results[2].manager == "services")
assert(result.results[3].manager == "shell")
assert(result.results[4].manager == "assets")
assert(result.results[5].manager == "deploy")

print("")
print("RC1-08 OK : Executor agrège les ExecutionResult des managers.")
