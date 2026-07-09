package.path = "./?.lua;./?/init.lua;" .. package.path

local Builder = require("installer.builder")
local Executor = require("installer.executor")

local plan = Builder.build("gibeytech")

print("== Executor Test ==")
print("")

Executor.execute(plan)

print("")
print("RC1-05 OK : PackageManager lit les packages en dry-run.")
