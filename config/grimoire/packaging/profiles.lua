local Profiles = {}

Profiles.beginner = {
    terminal = "ghostty",
    shell = "fish",
    browser = "brave",
    editor = "vscode",
    file_manager = "thunar",
    organization = "obsidian",
}

Profiles.advanced = {
    terminal = "ghostty",
    shell = "fish",
    browser = "brave",
    editor = "neovim",
    file_manager = "thunar",
    organization = "obsidian",
}

Profiles.gibeytech = {
    terminal = "kitty",
    extra_terminals = {
        "ghostty",
    },

    shell = "fish",
    browser = "brave",

    editor = "neovim",
    extra_editors = {
        "vscode",
    },

    file_manager = "thunar",
    organization = "obsidian",
}

Profiles.custom = {}

return Profiles
