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
                name = "hypr-grimoire-loader",
                source = "../../config/hypr/grimoire-loader.lua",
                destination = "~/.config/hypr/grimoire-loader.lua",
                operation = "copy",
                overwrite = false,
            },

            {
                name = "hypridle",
                source = "../../config/hypr/hypridle.conf",
                destination = "~/.config/hypr/hypridle.conf",
                operation = "copy",
                overwrite = false,
            },

            {
                name = "hyprlock",
                source = "../../config/hypr/hyprlock.conf",
                destination = "~/.config/hypr/hyprlock.conf",
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
