return {
    packages = {
        timeout_seconds = 3600,
        kill_after_seconds = 15,

        -- Le code de sortie de pacman ne distingue pas assez
        -- finement les erreurs transitoires des erreurs permanentes.
        -- Le retry reste donc désactivé par défaut sur le profil réel.
        retry = false,
    },
}
