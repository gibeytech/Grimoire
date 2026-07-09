local Preview = {}

function Preview.summary(plan)
    local profile = plan:getProfile()

    local lines = {}

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

    return table.concat(lines, "\n")
end

function Preview.show(plan)
    print(Preview.summary(plan))
end

function Preview.render(plan)
    return Preview.summary(plan)
end

function Preview.preview(plan)
    return Preview.summary(plan)
end

return Preview
