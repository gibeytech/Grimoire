package.path =
   "./?.lua;./?/init.lua;"
      .. package.path

local Builder = require(
   "installer.builder"
)

local PackageManager = require(
   "installer.managers.package_manager"
)

local ExecutionPlanBuilder = require(
   "installer.execution_plan_builder"
)

print(
   "== Shell Runtime RC4-C1 Package Order Test =="
)

local installation_plan =
   Builder.build("gibeytech")

local packages =
   PackageManager.collect_packages(
      installation_plan
   )

local quickshell_count = 0
local quickshell_index = nil

for index, package in ipairs(packages) do
   if package == "quickshell" then
      quickshell_count =
         quickshell_count + 1

      quickshell_index = index
   end
end

assert(quickshell_count == 1)
assert(quickshell_index == 7)
assert(#packages == 19)

local expected_command =
   "sudo pacman -S --needed "
   .. "git curl wget unzip rsync "
   .. "hyprland quickshell kitty thunar swaync "
   .. "neovim gcc make ripgrep fd "
   .. "vlc mpv gimp inkscape"

local package_command =
   PackageManager.build_pacman_command(
      packages
   )

assert(package_command == expected_command)

local execution_plan =
   ExecutionPlanBuilder.build(
      installation_plan,
      {
         dry_run = true,
      }
   )

local actions =
   execution_plan:getActions()

assert(#actions == 12)

local package_action_index = nil
local shell_action_index = nil
local deploy_action_index = nil
local service_indices = {}
local filesystem_indices = {}

for index, action in ipairs(actions) do
   if action.manager == "packages"
      and action.name == "install-packages"
   then
      package_action_index = index

      assert(action.type == "command")
      assert(action.count == 19)
      assert(action.command == expected_command)
   elseif action.type == "service_operation" then
      table.insert(
         service_indices,
         index
      )
   elseif action.type == "shell_operation" then
      shell_action_index = index

      assert(action.manager == "shell")
      assert(action.name == "deploy-runtime")
      assert(action.runtime == "grimoire-shell")
   elseif action.type == "file_operation" then
      table.insert(
         filesystem_indices,
         index
      )

      if action.manager == "deploy" then
         deploy_action_index = index
      end
   end
end

assert(package_action_index == 1)
assert(#service_indices == 6)

for expected = 1, 6 do
   assert(
      service_indices[expected]
         == expected + 1
   )
end

assert(shell_action_index == 8)
assert(#filesystem_indices == 4)

for _, index in ipairs(
   filesystem_indices
) do
   assert(index > shell_action_index)
end

assert(deploy_action_index == 12)

print("")
print(
   "Paquets       : "
      .. tostring(#packages)
)

print(
   "Quickshell    : position "
      .. tostring(quickshell_index)
)

print(
   "Action Shell  : position "
      .. tostring(shell_action_index)
)

print("")
print(
   "RC4-C1 OK : Quickshell est installé avant "
      .. "le déploiement du runtime Grimoire Shell."
)
