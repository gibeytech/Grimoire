local ExecutionPlan = require("installer.model.execution_plan")
local PackageManager = require("installer.managers.package_manager")
local PathResolver = require("installer.path_resolver")

local ExecutionPlanBuilder = {}

local function execution_mode(options)
    options = options or {}

    if options.dry_run ~= false then
        return "dry-run"
    end

    if options.apply_real == true then
        return "apply-real"
    end

    return "apply-safe"
end

local function add_action(actions, action)
    action.executed = false
    table.insert(actions, action)
end

local function value_is_present(value)
    return value ~= nil and tostring(value) ~= ""
end

local function clone_sequential_table(value)
    if type(value) ~= "table" then
        return value
    end

    local clone = {}

    for index, item in ipairs(value) do
        clone[index] = item
    end

    return clone
end

local function clone_retry_policy(value)
    if type(value) ~= "table" then
        return value
    end

    local clone = {}

    for key, item in pairs(value) do
        if key == "exit_codes" then
            clone[key] = clone_sequential_table(item)
        else
            clone[key] = item
        end
    end

    return clone
end

local function package_robustness(plan)
    if type(plan.getRobustness) ~= "function" then
        return {}
    end

    local robustness = plan:getRobustness()

    if type(robustness) ~= "table"
        or type(robustness.packages) ~= "table"
    then
        return {}
    end

    return robustness.packages
end

local function path_is_absolute(path)
    return value_is_present(path)
        and tostring(path):sub(1, 1) == "/"
end

local function path_uses_home(path)
    if not value_is_present(path) then
        return false
    end

    local string_path = tostring(path)

    return string_path == "~"
        or string_path:sub(1, 2) == "~/"
        or string_path == "$HOME"
        or string_path:sub(1, 6) == "$HOME/"
        or string_path == "${HOME}"
        or string_path:sub(1, 8) == "${HOME}/"
end

local function join_paths(base, relative)
    local normalized_base = tostring(base)
    local normalized_relative = tostring(relative)

    while #normalized_base > 1
        and normalized_base:sub(-1) == "/"
    do
        normalized_base = normalized_base:sub(1, -2)
    end

    while normalized_relative:sub(1, 1) == "/" do
        normalized_relative = normalized_relative:sub(2)
    end

    if normalized_relative == "" then
        return normalized_base
    end

    return normalized_base .. "/" .. normalized_relative
end

local function resolve_path(path, options)
    local result = PathResolver.resolve(path, {
        home = options and options.home,
    })

    if not result.ok then
        error(
            "Impossible de résoudre le chemin "
                .. tostring(path)
                .. ": "
                .. tostring(result.error)
        )
    end

    return result.path
end

local function resolve_profile_source(profile, source, options)
    if not value_is_present(source) then
        return source
    end

    if path_is_absolute(source) or path_uses_home(source) then
        return resolve_path(source, options)
    end

    if profile and value_is_present(profile.root) then
        return join_paths(profile.root, source)
    end

    return source
end

local function add_package_actions(actions, plan)
    local packages = PackageManager.collect_packages(plan)
    local command = PackageManager.build_pacman_command(packages)
    local robustness = package_robustness(plan)

    if command then
        add_action(actions, {
            type = "command",
            manager = "packages",
            name = "install-packages",
            command = command,
            count = #packages,
            timeout_seconds = robustness.timeout_seconds,
            kill_after_seconds = robustness.kill_after_seconds,
            retry = clone_retry_policy(robustness.retry),
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

local function add_asset_actions(actions, plan, options)
    local profile = plan:getProfile()
    local assets = plan:getAssets()

    for name, config in pairs(assets or {}) do
        add_action(actions, {
            type = "file_operation",
            manager = "assets",
            name = name,
            operation = {
                type = "copy",
                source = resolve_profile_source(
                    profile,
                    config.source,
                    options
                ),
                destination = resolve_path(
                    config.destination,
                    options
                ),
                overwrite = config.overwrite,
            },
        })
    end
end

local function add_deploy_actions(actions, plan, options)
    local profile = plan:getProfile()
    local dotfiles = plan:getDotfiles()

    if dotfiles and dotfiles.source then
        add_action(actions, {
            type = "file_operation",
            manager = "deploy",
            name = "dotfiles",
            operation = {
                type = "symlink",
                source = resolve_profile_source(
                    profile,
                    dotfiles.source,
                    options
                ),
                destination = resolve_path(
                    dotfiles.destination or "~/.config",
                    options
                ),
                overwrite = dotfiles.overwrite,
            },
        })
    end
end

function ExecutionPlanBuilder.build(plan, options)
    options = options or {}

    local actions = {}

    add_package_actions(actions, plan)
    add_service_actions(actions, plan)
    add_shell_actions(actions, plan)
    add_asset_actions(actions, plan, options)
    add_deploy_actions(actions, plan, options)

    return ExecutionPlan:new({
        profile = plan:getProfile(),
        mode = execution_mode(options),
        actions = actions,
        installation_plan = plan,
    })
end

return ExecutionPlanBuilder
