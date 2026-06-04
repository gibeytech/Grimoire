local Bootstrap = {}

Bootstrap.packages = {
    {
        name = "Git",
        package = "git",
        reason = "Cloner le dépôt Grimoire",
    },

    {
        name = "OpenSSH",
        package = "openssh",
        reason = "Accès SSH et Git",
    },
}

return Bootstrap
