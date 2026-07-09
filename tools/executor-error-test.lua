package.path = "./?.lua;./?/init.lua;" .. package.path

local Executor = require("installer.executor")

print("== Executor RC1-09 Error Test ==")

local plan = {
    packages = {
        groups = {},
    },
}

local result = Executor.execute(plan, {
    dry_run = true,
    force_fail_at = "services",
})

assert(result.ok == false)
assert(result.dry_run == true)
assert(result.failed_at == "services")
assert(result.error == "Erreur forcée pour test RC1-09")
assert(type(result.results) == "table")
assert(#result.results == 2)

assert(result.results[1].manager == "packages")
assert(result.results[2].manager == "services")

print("")
print("RC1-09 OK : Executor stoppe proprement sur erreur manager.")
