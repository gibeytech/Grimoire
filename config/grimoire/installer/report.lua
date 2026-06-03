local Report = {}

local Packaging = require("packaging")

function Report.generate(config)
    local split = Packaging.setup.split_packages(config)

    local lines = {}

    table.insert(lines, "=================================")
    table.insert(lines, " Grimoire V2 Installation Report ")
    table.insert(lines, "=================================")
    table.insert(lines, "")

    table.insert(lines, "Profile")
    table.insert(lines, "-------")
    table.insert(lines, config.profile)
    table.insert(lines, "")

    table.insert(lines, "Applications")
    table.insert(lines, "------------")
    table.insert(lines, config.terminal.name)

    if config.extra_terminals then
        for _, terminal in ipairs(config.extra_terminals) do
            table.insert(lines, terminal.name)
        end
    end

    table.insert(lines, config.shell.name)
    table.insert(lines, config.browser.name)
    table.insert(lines, config.editor.name)

    if config.organization then
        table.insert(lines, config.organization.name)
    end

    table.insert(lines, "")

    if config.layers.developer then
        table.insert(lines, "Developer Layer")
        table.insert(lines, "---------------")
        table.insert(lines, config.layers.developer.name)
        table.insert(lines, "")
    end

    if config.layers.containers then
        table.insert(lines, "Container Layer")
        table.insert(lines, "---------------")
        table.insert(lines, config.layers.containers.name)
        table.insert(lines, "")
    end

    if config.layers.virtualization then
        table.insert(lines, "Virtualization Layer")
        table.insert(lines, "-------------------")
        table.insert(lines, config.layers.virtualization.name)
        table.insert(lines, "")
    end

    table.insert(lines, "Packages")
    table.insert(lines, "--------")
    table.insert(lines, "Total    : " .. (#split.official + #split.aur))
    table.insert(lines, "Official : " .. #split.official)
    table.insert(lines, "AUR      : " .. #split.aur)

    return table.concat(lines, "\n")
end

return Report
