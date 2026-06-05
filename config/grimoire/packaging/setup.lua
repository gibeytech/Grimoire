local Setup = {}

local Profiles = require("packaging.profiles")
local Catalogue = require("packaging.catalogue")
local Layers = require("packaging.layers")
local Core = require("packaging.core")
local Desktop = require("packaging.desktop")

local aur_packages = {
    ["brave-bin"] = true,
    ["visual-studio-code-bin"] = true,
    ["joplin-appimage"] = true,
}

local function resolve_extra_items(source, keys, error_label)
    local items = {}

    if not keys then
        return items
    end

    for _, key in ipairs(keys) do
        local item = source[key]

        if not item then
            error("Unknown " .. error_label .. ": " .. tostring(key))
        end

        table.insert(items, item)
    end

    return items
end

function Setup.new(profile, options)
    options = options or {}

    local profile_data = Profiles[profile]

    if not profile_data then
        error("Unknown profile: " .. tostring(profile))
    end

    local config = {
        profile = profile,

        core = Core.packages,
        desktop = Desktop.packages,

        terminal = Catalogue.terminals[profile_data.terminal],

        extra_terminals = resolve_extra_items(
            Catalogue.terminals,
            profile_data.extra_terminals,
            "extra terminal"
        ),

        shell = Catalogue.shells[profile_data.shell],
        browser = Catalogue.browsers[profile_data.browser],

        editor = Catalogue.editors[profile_data.editor],
	file_manager = Catalogue.file_managers[profile_data.file_manager],


        extra_editors = resolve_extra_items(
            Catalogue.editors,
            profile_data.extra_editors,
            "extra editor"
        ),

        organization = Catalogue.organization[profile_data.organization],

        layers = {},
    }

    if options.developer then
        local developer_profile =
            Layers.developer.profiles[options.developer]

        if not developer_profile then
            error("Unknown developer profile: " .. tostring(options.developer))
        end

        config.layers.developer = developer_profile
    end

    if options.containers then
        local container_choice =
            Layers.containers.choices[options.containers]

        if not container_choice then
            error("Unknown container choice: " .. tostring(options.containers))
        end

        config.layers.containers = container_choice
    end

    if options.virtualization then
        local virtualization_choice =
            Layers.virtualization.choices[options.virtualization]

        if not virtualization_choice then
            error("Unknown virtualization choice: " .. tostring(options.virtualization))
        end

        config.layers.virtualization = virtualization_choice
    end

    return config
end

function Setup.list_packages(config)
    local packages = {}

    -- Core
    for _, component in ipairs(config.core) do
        table.insert(packages, component.package)
    end

    -- Desktop
    for _, component in ipairs(config.desktop) do
        table.insert(packages, component.package)
    end

    -- Profil
    local components = {
        config.terminal,
        config.shell,
        config.browser,
        config.editor,
	config.file_manager,
        config.organization,
    }

    for _, component in ipairs(components) do
        if component and component.package then
            table.insert(packages, component.package)
        end
    end

    if config.extra_terminals then
        for _, terminal in ipairs(config.extra_terminals) do
            table.insert(packages, terminal.package)
        end
    end

    if config.extra_editors then
        for _, editor in ipairs(config.extra_editors) do
            table.insert(packages, editor.package)
        end
    end

    -- Layers
    if config.layers.developer then
        for _, package in ipairs(config.layers.developer.tools) do
            table.insert(packages, package)
        end
    end

    if config.layers.containers then
        for _, package in ipairs(config.layers.containers.packages) do
            table.insert(packages, package)
        end
    end

    if config.layers.virtualization then
        for _, package in ipairs(config.layers.virtualization.packages) do
            table.insert(packages, package)
        end
    end

    return packages
end

function Setup.split_packages(config)
    local official = {}
    local aur = {}

    for _, package in ipairs(Setup.list_packages(config)) do
        if aur_packages[package] then
            table.insert(aur, package)
        else
            table.insert(official, package)
        end
    end

    return {
        official = official,
        aur = aur,
    }
end

function Setup.install_command(config)
    local split = Setup.split_packages(config)
    local commands = {}

    if #split.official > 0 then
        table.insert(commands,
            "sudo pacman -S " .. table.concat(split.official, " "))
    end

    if #split.aur > 0 then
        table.insert(commands,
            "yay -S " .. table.concat(split.aur, " "))
    end

    return table.concat(commands, "\n")
end

function Setup.summary(config)
    local lines = {}

    table.insert(lines, "Profile : " .. config.profile)
    table.insert(lines, "")
    table.insert(lines, "Core : " .. tostring(#config.core) .. " packages")
    table.insert(lines, "Desktop : " .. tostring(#config.desktop) .. " packages")
    table.insert(lines, "")

    table.insert(lines, "Applications")

    table.insert(lines, "- " .. config.terminal.name)

    for _, terminal in ipairs(config.extra_terminals) do
        table.insert(lines, "- " .. terminal.name)
    end

    table.insert(lines, "- " .. config.shell.name)
    table.insert(lines, "- " .. config.browser.name)
    table.insert(lines, "- " .. config.editor.name)
    table.insert(lines, "- " .. config.file_manager.name)

    for _, editor in ipairs(config.extra_editors) do
        table.insert(lines, "- " .. editor.name)
    end

    table.insert(lines, "- " .. config.organization.name)

    return table.concat(lines, "\n")
end

return Setup
