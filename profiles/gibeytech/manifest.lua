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
        robustness = "config/robustness.lua",
    },

    dotfiles = {
        entries = {
            {
                name = "hypr",
                source = "../../config/hypr",
                destination = "~/.config/hypr",
                operation = "copy",
                overwrite = false,
            },

            {
                name = "kitty",
                source = "../../config/kitty/kitty.conf",
                destination = "~/.config/kitty/kitty.conf",
                operation = "copy",
                overwrite = false,
            },

            {
                name = "fish",
                source = "../../config/fish/config.fish",
                destination = "~/.config/fish/config.fish",
                operation = "copy",
                overwrite = false,
            },

            {
                name = "swaync",
                source = "../../config/swaync",
                destination = "~/.config/swaync",
                operation = "copy",
                overwrite = false,
            },

            {
                name = "wlogout",
                source = "../../config/wlogout",
                destination = "~/.config/wlogout",
                operation = "copy",
                overwrite = false,
            },

            {
                name = "grimoire",
                source = "../../config/grimoire",
                destination = "~/.config/grimoire",
                operation = "copy",
                overwrite = false,
            },
        },
    },

    minimum_core = "3.0.0",
}
