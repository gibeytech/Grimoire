local SummaryBuilder = {}

local function ensure(summary, key)
    if not summary[key] then
        summary[key] = {
            actions = 0,
        }
    end

    return summary[key]
end

local function extract_file_operation(details)
    if not details then
        return nil
    end

    if details.action and details.action.operation then
        return details.action.operation
    end

    if details.operation and details.operation.operation then
        return details.operation.operation
    end

    if details.operation and details.operation.type then
        return details.operation
    end

    return nil
end

function SummaryBuilder.build(results)
    local summary = {}

    for _, result in ipairs(results or {}) do
        local manager = result.manager or "unknown"
        local bucket = ensure(summary, manager)

        bucket.actions = bucket.actions + 1

        local details = result.details or {}

        if details.runner then
            bucket.command = details.runner.command
        end

        if details.service then
            bucket.enable = bucket.enable or 0
            bucket.disable = bucket.disable or 0

            if details.operation == "enable" then
                bucket.enable = bucket.enable + 1
            elseif details.operation == "disable" then
                bucket.disable = bucket.disable + 1
            end
        end

        if details.module then
            bucket.runtime = details.runtime
            bucket.modules = (bucket.modules or 0) + 1
        end

        local file_operation = extract_file_operation(details)

        if file_operation then
            if file_operation.type == "copy" then
                bucket.copies = (bucket.copies or 0) + 1
            elseif file_operation.type == "symlink" then
                bucket.symlinks = (bucket.symlinks or 0) + 1
            end
        end
    end

    return summary
end

return SummaryBuilder
