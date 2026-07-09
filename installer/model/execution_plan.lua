local ExecutionPlan = {}
ExecutionPlan.__index = ExecutionPlan

function ExecutionPlan:new(data)
    assert(type(data) == "table", "ExecutionPlan:new() attend une table.")

    local plan = setmetatable({}, self)

    plan.profile = data.profile or {}
    plan.mode = data.mode or "dry-run"
    plan.actions = data.actions or {}
    plan.installation_plan = data.installation_plan

    return plan
end

function ExecutionPlan:getProfile()
    return self.profile
end

function ExecutionPlan:getMode()
    return self.mode
end

function ExecutionPlan:getActions()
    return self.actions
end

function ExecutionPlan:countActions()
    return #self.actions
end

function ExecutionPlan:getInstallationPlan()
    return self.installation_plan
end

return ExecutionPlan
