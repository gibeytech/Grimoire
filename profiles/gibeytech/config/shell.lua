return {
    runtime = "grimoire-shell",

    deployment = {
        -- Les dépôts grimoire et grimoire-shell sont actuellement
        -- voisins dans le workspace GrimoireLab.
        source = "../grimoire-shell/quickshell",

        destination = "~/.config/grimoire-shell",

        strategy = "copy",
        overwrite = "error",
        entrypoint = "shell.qml",
    },

    -- Modules souhaités par le profil. Cette liste ne représente
    -- pas nécessairement un répertoire physique par module.
    modules = {
        "bar",
        "hub",
        "launcher",
        "notifications",
        "media",
        "bluetooth",
        "network",
        "battery",
    },
}
