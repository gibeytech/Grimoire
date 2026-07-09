local ExecutionPlan = require("installer.model.execution_plan")
local PackageManager = require("installer.managers.package_manager")

local ExecutionPlanBuilder = {}

local function execution_mode(options)
    options = options or {}

    if options.dry_run ~= false then
        return "dry-run"
    end

    return "apply-safe"
end

local function add_action(actions, action)
    action.executed = false
    table.insert(actions, action)
end

local function add_package_actions(actions, plan)
    local packages = PackageManager.collect_packages(plan)
    local command = PackageManager.build_pacman_command(packages)

    if command then
        add_action(actions, {
            type = "command",
            manager = "packages",
            name = "install-packages",
            command = command,
            count = #packages,
        })
    end
end

local function add_service_actions(actions, plan)
    local services = plan:getServices()

    for _, service in ipairs(services.enabled or {}) do
        add_action(actions, {
            type = "service_operation",
            manager = "services",
            name = "enable-service",
            service = service,
            operation = "enable",
        })
    end

    for _, service in ipairs(services.disabled or {}) do
        add_action(actions, {
            type = "service_operation",
            manager = "services",
            name = "disable-service",
            service = service,
            operation = "disable",
        })
    end
end

local function add_shell_actions(actions, plan)
    local shell = plan:getShell()

    for _, module in ipairs(shell.modules or {}) do
        add_action(actions, {
            type = "shell_operation",
            manager = "shell",
            name = "prepare-module",
            module = module,
            runtime = shell.runtime,
        })
    end
end

local function add_asset_actions(actions, plan)
    local assets = plan:getAssets()

    for name, config in pairs(assets or {}) do
        add_action(actions, {
            type = "file_operation",
            manager = "assets",
            name = name,
            operation = {
                type = "copy",
                source = config.source,
                destination = config.destination,
            },
        })
    end
end

local function add_deploy_actions(actions, plan)
    local profile = plan:getProfile()
    local dotfiles = plan:getDotfiles()

    if dotfiles and dotfiles.source then
        add_action(actions, {
            type = "file_operation",
            manager = "deploy",
            name = "dotfiles",
            operation = {
                type = "symlink",
                source = profile.root .. "/" .. dotfiles.source,
                destination = "~/.config",
            },
        })
    end
end

function ExecutionPlanBuilder.build(plan, options)
    local actions = {}

    add_package_actions(actions, plan)
    add_service_actions(actions, plan)
    add_shell_actions(actions, plan)
    add_asset_actions(actions, plan)
    add_deploy_actions(actions, plan)

       return ExecutionPlan:new({
        profile = plan:getProfile(),
        mode = execution_mode(options),
        actions = actions,
        installation_plan = plan,
    })

   end

return ExecutionPlanBuilder
