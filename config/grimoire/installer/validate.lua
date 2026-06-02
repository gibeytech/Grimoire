local Validate = {}

local Packaging = require("packaging")

local function require_component(errors, config, key)
    if not config[key] then
        table.insert(errors, "Missing component: " .. key)
        return
    end

    if not config[key].name then
        table.insert(errors, "Missing name for component: " .. key)
    end

    if not config[key].package then
        table.insert(errors, "Missing package for component: " .. key)
    end
end

function Validate.check(config)
    local errors = {}

    if not config then
        return {
            valid = false,
            errors = { "Missing config" },
        }
    end

    if not config.profile then
        table.insert(errors, "Missing profile")
    end

    require_component(errors, config, "terminal")
    require_component(errors, config, "shell")
    require_component(errors, config, "browser")
    require_component(errors, config, "editor")

    local packages = Packaging.setup.list_packages(config)

    if #packages == 0 then
        table.insert(errors, "No packages found")
    end

    return {
        valid = #errors == 0,
        errors = errors,
    }
end

return Validate
