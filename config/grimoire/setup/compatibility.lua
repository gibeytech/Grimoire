local Compatibility = {}

local official_distros = {
    arch = true,
    cachyos = true,
    endeavouros = true,
}

local function contains(value, pattern)
    if not value then
        return false
    end

    return string.lower(value):find(pattern, 1, true) ~= nil
end

local function add(report, ok, label, message)
    table.insert(report.checks, {
        ok = ok,
        label = label,
        message = message,
    })
end

function Compatibility.evaluate(system)
    local report = {
        score = 0,
        level = "non validé",
        checks = {},
        messages = {},
    }

    -- Distribution
    if contains(system.distribution, "arch")
        or contains(system.distribution, "cachyos")
        or contains(system.distribution, "endeavouros") then
        report.score = report.score + 30
        add(report, true, "Distribution", "Distribution compatible")
    else
        report.score = report.score + 10
        add(report, false, "Distribution", "Distribution non officiellement validée")
    end

    -- Session
    if system.session == "wayland" then
        report.score = report.score + 20
        add(report, true, "Session", "Wayland détecté")
    else
        report.score = report.score + 5
        add(report, false, "Session", "Session Wayland non détectée")
    end

    -- Desktop / WM
    if contains(system.desktop, "hyprland") then
        report.score = report.score + 20
        add(report, true, "WM", "Hyprland détecté")
    else
        report.score = report.score + 5
        add(report, false, "WM", "Hyprland non détecté")
    end

    -- Composants principaux
    local components = {
        { key = "waybar", label = "Waybar" },
        { key = "rofi", label = "Rofi" },
        { key = "fish", label = "Fish" },
        { key = "kitty", label = "Kitty" },
        { key = "swaync", label = "SwayNC" },
        { key = "nvim", label = "Neovim" },
    }

    for _, component in ipairs(components) do
        if system.commands and system.commands[component.key] then
            report.score = report.score + 5
            add(report, true, component.label, component.label .. " détecté")
        else
            add(report, false, component.label, component.label .. " non détecté")
        end
    end

    if report.score > 100 then
        report.score = 100
    end

    if report.score >= 90 then
        report.level = "compatible"
    elseif report.score >= 70 then
        report.level = "compatible avec réserves"
    elseif report.score >= 40 then
        report.level = "support limité"
    else
        report.level = "non validé"
    end

    return report
end

return Compatibility
