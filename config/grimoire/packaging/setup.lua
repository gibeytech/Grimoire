local Setup = {}

local Profiles = require("packaging.profiles")
local Catalogue = require("packaging.catalogue")
local Layers = require("packaging.layers")

function Setup.new(profile, options)
    options = options or {}

    local profile_data = Profiles[profile]

    if not profile_data then
        error("Unknown profile: " .. tostring(profile))
    end

    local config = {
        profile = profile,

        terminal = Catalogue.terminals[profile_data.terminal],
        shell = Catalogue.shells[profile_data.shell],
        browser = Catalogue.browsers[profile_data.browser],
        editor = Catalogue.editors[profile_data.editor],

        layers = {},
    }

    if options.developer then
        local developer_profile =
            Layers.developer.profiles[options.developer]

        if not developer_profile then
            error(
                "Unknown developer profile: "
                    .. tostring(options.developer)
            )
        end

        config.layers.developer = developer_profile
    end

    if options.containers then
        local container_choice =
            Layers.containers.choices[options.containers]

        if not container_choice then
            error(
                "Unknown container choice: "
                    .. tostring(options.containers)
            )
        end

        config.layers.containers = container_choice
    end

    if options.virtualization then
        local virtualization_choice =
            Layers.virtualization.choices[options.virtualization]

        if not virtualization_choice then
            error(
                "Unknown virtualization choice: "
                    .. tostring(options.virtualization)
            )
        end

        config.layers.virtualization = virtualization_choice
    end

    return config
end

function Setup.list_packages(config)
    local packages = {}

    for _, component in pairs(config) do
        if type(component) == "table" and component.package then
            table.insert(packages, component.package)
        end
    end

    if config.layers and config.layers.developer then
        for _, package in ipairs(config.layers.developer.tools) do
            table.insert(packages, package)
        end
    end

    if config.layers and config.layers.containers then
        for _, package in ipairs(config.layers.containers.packages) do
            table.insert(packages, package)
        end
    end

    if config.layers and config.layers.virtualization then
        for _, package in ipairs(config.layers.virtualization.packages) do
            table.insert(packages, package)
        end
    end

    return packages
end

function Setup.summary(config)
    local lines = {}

    table.insert(lines, "Profile : " .. config.profile)
    table.insert(lines, "")

    table.insert(lines, "Applications")
    table.insert(lines, "- " .. config.terminal.name)
    table.insert(lines, "- " .. config.shell.name)
    table.insert(lines, "- " .. config.browser.name)
    table.insert(lines, "- " .. config.editor.name)
    table.insert(lines, "")

    if config.layers.developer then
        table.insert(lines, "Developer Layer")
        table.insert(lines, "- " .. config.layers.developer.name)
        table.insert(lines, "")
    end

    if config.layers.containers then
        table.insert(lines, "Container Layer")
        table.insert(lines, "- " .. config.layers.containers.name)
        table.insert(lines, "")
    end

    if config.layers.virtualization then
        table.insert(lines, "Virtualization Layer")
        table.insert(lines, "- " .. config.layers.virtualization.name)
        table.insert(lines, "")
    end

    table.insert(lines, "Packages")

    for _, package in ipairs(Setup.list_packages(config)) do
        table.insert(lines, "- " .. package)
    end

    return table.concat(lines, "\n")
end

return Setup
