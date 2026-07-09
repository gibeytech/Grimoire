package.path = "./?.lua;./?/init.lua;" .. package.path

local Builder = require("installer.builder")
local Preview = require("installer.preview")

local profile_id = arg[1] or "gibeytech"

local plan = Builder.build(profile_id)

print(Preview.summary(plan))
print("")
print("RC1-02 OK : Builder retourne un objet InstallationPlan.")
