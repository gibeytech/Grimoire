local Preview = {}

local Packaging = require("packaging")

local function add_section(lines, title)
    table.insert(lines, "")
    table.insert(lines, title)
    table.insert(lines, string.rep("-", #title))
end

local function add_list(lines, items)
    for _, item in ipairs(items) do
        table.insert(lines, "- " .. item)
    end
end

function Preview.summary(config)
    local lines = {}
    local split = Packaging.setup.split_packages(config)

    table.insert(lines, "=================================")
    table.insert(lines, "      Grimoire V2 Preview")
    table.insert(lines, "=================================")

    add_section(lines, "Profile")
    table.insert(lines, config.profile)

    add_section(lines, "Applications")
    table.insert(lines, "- " .. config.terminal.name)
    table.insert(lines, "- " .. config.shell.name)
    table.insert(lines, "- " .. config.browser.name)
    table.insert(lines, "- " .. config.editor.name)

    if config.layers.developer then
        add_section(lines, "Developer Layer")
        table.insert(lines, "- " .. config.layers.developer.name)
    end

    if config.layers.containers then
        add_section(lines, "Container Layer")
        table.insert(lines, "- " .. config.layers.containers.name)
    end

    if config.layers.virtualization then
        add_section(lines, "Virtualization Layer")
        table.insert(lines, "- " .. config.layers.virtualization.name)
    end

    add_section(lines, "Official Packages (" .. #split.official .. ")")
    add_list(lines, split.official)

    add_section(lines, "AUR Packages (" .. #split.aur .. ")")
    add_list(lines, split.aur)

    add_section(lines, "Install Commands")
    table.insert(lines, Packaging.setup.install_command(config))

    return table.concat(lines, "\n")
end

function Preview.install_command(config)
    return Packaging.setup.install_command(config)
end

return Preview
