local Preview = {}

local function count_actions_by_type(execution_plan)
    local counts = {}

    if not execution_plan then
        return counts
    end

    for _, action in ipairs(execution_plan:getActions() or {}) do
        local action_type = action.type or "unknown"
        counts[action_type] = (counts[action_type] or 0) + 1
    end

    return counts
end

local function append_installation_plan(lines, plan)
    local profile = plan:getProfile()

    table.insert(lines, "== Installation Plan ==")
    table.insert(lines, "")

    table.insert(lines, "Profil")
    table.insert(lines, "-------")
    table.insert(lines, "Nom      : " .. profile.name)
    table.insert(lines, "ID       : " .. profile.id)
    table.insert(lines, "Version  : " .. profile.version)
    table.insert(lines, "")

    table.insert(lines, "Composants")

    if plan:getPackages() then
        table.insert(lines, "  ✓ Packages")
    end

    if plan:getServices() then
        table.insert(lines, "  ✓ Services")
    end

    if plan:getShell() then
        table.insert(lines, "  ✓ Shell")
    end

    if plan:getTheme() then
        table.insert(lines, "  ✓ Theme")
    end

    if plan:getAssets() then
        table.insert(lines, "  ✓ Assets")
    end

    table.insert(lines, "")
end

local function append_execution_action(lines, action)
    local label = "  [" .. tostring(action.type) .. "] " .. tostring(action.manager) .. "/" .. tostring(action.name)

    if action.type == "command" then
        label = label .. " (" .. tostring(action.count or 0) .. " packages)"
    elseif action.type == "service_operation" then
        label = label .. " " .. tostring(action.service)
    elseif action.type == "shell_operation" then
        if type(action.modules) == "table" then
            label =
                label
                .. " "
                .. tostring(action.runtime)
                .. " ("
                .. tostring(#action.modules)
                .. " modules) "
                .. tostring(action.source)
                .. " -> "
                .. tostring(action.destination)
        else
            label =
                label
                .. " "
                .. tostring(action.module)
        end
    elseif action.type == "file_operation" and action.operation then
        label = label
            .. " "
            .. tostring(action.operation.type)
            .. " "
            .. tostring(action.operation.source)
            .. " -> "
            .. tostring(action.operation.destination)
    end

    table.insert(lines, label)
end

local function append_execution_plan(lines, execution_plan)
    if not execution_plan then
        return
    end

    local counts = count_actions_by_type(execution_plan)

    table.insert(lines, "== Execution Plan ==")
    table.insert(lines, "")
    table.insert(lines, "Mode    : " .. tostring(execution_plan:getMode()))
    table.insert(lines, "Actions : " .. tostring(execution_plan:countActions()))
    table.insert(lines, "")

    table.insert(lines, "Types")
    table.insert(lines, "-----")
    table.insert(lines, "  command           : " .. tostring(counts.command or 0))
    table.insert(lines, "  service_operation : " .. tostring(counts.service_operation or 0))
    table.insert(lines, "  shell_operation   : " .. tostring(counts.shell_operation or 0))
    table.insert(lines, "  file_operation    : " .. tostring(counts.file_operation or 0))
    table.insert(lines, "")

    table.insert(lines, "Actions")
    table.insert(lines, "-------")

    for _, action in ipairs(execution_plan:getActions() or {}) do
        append_execution_action(lines, action)
    end

    table.insert(lines, "")
end

function Preview.summary(plan, execution_plan)
    local lines = {}

    append_installation_plan(lines, plan)
    append_execution_plan(lines, execution_plan)

    return table.concat(lines, "\n")
end

function Preview.show(plan, execution_plan)
    print(Preview.summary(plan, execution_plan))
end

function Preview.render(plan, execution_plan)
    return Preview.summary(plan, execution_plan)
end

function Preview.preview(plan, execution_plan)
    return Preview.summary(plan, execution_plan)
end

return Preview
