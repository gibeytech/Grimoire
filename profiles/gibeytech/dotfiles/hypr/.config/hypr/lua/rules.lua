-- ============================================================
-- WINDOW RULES
-- ============================================================

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Fenêtres flottantes centrées, ne chevauchent pas la Waybar
hl.window_rule({
    name = "center-floating",
    match = { float = true },
    move = "onscreen cursor -50% -50%",
})
