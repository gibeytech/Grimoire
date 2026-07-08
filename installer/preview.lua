local Preview = {}

function Preview.summary(plan)
    local lines = {}

    table.insert(lines, "== Installation Plan ==")
    table.insert(lines, "")

    table.insert(lines, "Profil")
    table.insert(lines, "-------")
    table.insert(lines, "Nom      : " .. plan.profile.name)
    table.insert(lines, "ID       : " .. plan.profile.id)
    table.insert(lines, "Version  : " .. plan.profile.version)
    table.insert(lines, "")

    table.insert(lines, "Composants")

    if plan.packages then
        table.insert(lines, "  ✓ Packages")
    end

    if plan.services then
        table.insert(lines, "  ✓ Services")
    end

    if plan.shell then
        table.insert(lines, "  ✓ Shell")
    end

    if plan.theme then
        table.insert(lines, "  ✓ Theme")
    end

    if plan.assets then
        table.insert(lines, "  ✓ Assets")
    end

    table.insert(lines, "")

    return table.concat(lines, "\n")
end

return Preview
