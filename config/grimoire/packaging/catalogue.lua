local Catalogue = {}

Catalogue.terminals = {
    ghostty = {
        name = "Ghostty",
        package = "ghostty",
        recommended = true,
    },

    kitty = {
        name = "Kitty",
        package = "kitty",
        recommended = false,
    },

    alacritty = {
        name = "Alacritty",
        package = "alacritty",
        recommended = false,
    },
}

Catalogue.shells = {
    fish = {
        name = "Fish",
        package = "fish",
        recommended = true,
    },

    zsh = {
        name = "Zsh",
        package = "zsh",
        recommended = false,
    },

    bash = {
        name = "Bash",
        package = "bash",
        recommended = false,
    },
}

Catalogue.browsers = {
    brave = {
        name = "Brave",
        package = "brave-bin",
        recommended = true,
    },

    firefox = {
        name = "Firefox",
        package = "firefox",
        recommended = false,
    },

    chromium = {
        name = "Chromium",
        package = "chromium",
        recommended = false,
    },
}

Catalogue.editors = {
    vscode = {
        name = "VSCode",
        package = "visual-studio-code-bin",
        recommended = true,
    },

    neovim = {
        name = "Neovim",
        package = "neovim",
        recommended = false,
    },

    zed = {
        name = "Zed",
        package = "zed",
        recommended = false,
    },
}

Catalogue.file_managers = {
    thunar = {
        name = "Thunar",
        package = "thunar",
        recommended = true,
    },

    dolphin = {
        name = "Dolphin",
        package = "dolphin",
        recommended = false,
    },

    yazi = {
        name = "Yazi",
        package = "yazi",
        recommended = false,
    },
}

Catalogue.organization = {
    obsidian = {
        name = "Obsidian",
        package = "obsidian",
        recommended = true,
    },

    cherrytree = {
        name = "CherryTree",
        package = "cherrytree",
        recommended = false,
    },

    joplin = {
        name = "Joplin",
        package = "joplin-appimage",
        recommended = false,
    },
}

return Catalogue
