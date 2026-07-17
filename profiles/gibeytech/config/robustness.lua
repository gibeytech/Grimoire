return {
    packages = {
        timeout_seconds = 3600,
        kill_after_seconds = 15,

        -- Pacman ne distingue pas assez finement les erreurs
        -- transitoires des erreurs permanentes.
        retry = false,
    },

    services = {
        -- Une opération systemctl normale doit rester courte.
        timeout_seconds = 30,
        kill_after_seconds = 5,

        -- Les mutations systemd sont idempotentes, mais un timeout
        -- peut survenir après une mutation partielle.
        retry = false,
    },

    shell = {
        -- Le déploiement peut recopier l'intégralité du runtime QML.
        timeout_seconds = 120,
        kill_after_seconds = 5,

        -- Un timeout peut survenir après la création partielle de la
        -- destination. Le rollback est disponible, mais le retry
        -- automatique reste désactivé.
        retry = false,
    },
}
