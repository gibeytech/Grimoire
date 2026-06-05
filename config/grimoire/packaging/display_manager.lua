local DisplayManager = {}

DisplayManager.choices = {
    sddm = {
        name = "SDDM",
        package = "sddm",
        service = "sddm.service",
        recommended = true,
        description = "Display Manager recommandé par Grimoire",
    },

    gdm = {
        name = "GDM",
        package = "gdm",
        service = "gdm.service",
        recommended = false,
        description = "Display Manager GNOME supporté",
    },

    ly = {
        name = "Ly",
        package = "ly",
        service = "ly.service",
        recommended = false,
        description = "Display Manager TUI minimal supporté",
    },
}

return DisplayManager
