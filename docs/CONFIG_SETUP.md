# Config Setup

## Objectif

`config.setup()` sert à déclarer les choix utilisateur de manière lisible, explicite et reproductible.

Grimoire fournit le cadre.
L'utilisateur choisit ses outils.

## Exemple cible

```lua
config.setup({
    terminal = {
        primary = "ghostty",
        secondary = "kitty",
    },

    shell = "fish",

    file_manager = {
        graphical = "thunar",
        terminal = "yazi",
    },

    editor = {
        graphical = "vscode",
        terminal = "nvim",
    },

    browser = "brave",

    theme = "grimoire",
})
