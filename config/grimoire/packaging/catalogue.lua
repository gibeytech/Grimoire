local Catalogue = {}

Catalogue.terminals = {
    ghostty = {
        name = "Ghostty",
        recommended = true,
    },

    kitty = {
        name = "Kitty",
        recommended = false,
    },

    alacritty = {
        name = "Alacritty",
        recommended = false,
    },
}

Catalogue.shells = {
    fish = {
        name = "Fish",
        recommended = true,
    },

    zsh = {
        name = "Zsh",
        recommended = false,
    },

    bash = {
        name = "Bash",
        recommended = false,
    },
}

Catalogue.browsers = {
    brave = {
        name = "Brave",
        recommended = true,
    },

    firefox = {
        name = "Firefox",
        recommended = false,
    },

    chromium = {
        name = "Chromium",
        recommended = false,
    },
}

Catalogue.editors = {
    vscode = {
        name = "VSCode",
        recommended = true,
    },

    neovim = {
        name = "Neovim",
        recommended = false,
    },

    zed = {
        name = "Zed",
        recommended = false,
    },
}

return Catalogue
