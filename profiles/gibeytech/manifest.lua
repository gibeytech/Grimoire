return {
    id = "gibeytech",
    name = "GibeyTech",
    version = "3.0.0",
    status = "reference",

    description = "Profil de référence de Grimoire V3.",

    target = {
        "cachyos",
        "archlinux",
    },

    config = {
        packages = "config/packages.lua",
        services = "config/services.lua",
        shell = "config/shell.lua",
        theme = "config/theme.lua",
        assets = "config/assets.lua",
    },

    dotfiles = {
        source = "dotfiles",
    },

    minimum_core = "3.0.0",
}
