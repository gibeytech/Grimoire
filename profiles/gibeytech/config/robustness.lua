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
        -- peut survenir après une mutation partielle. Le retry reste
        -- donc désactivé tant que la réconciliation post-timeout
        -- n'est pas explicitement contractualisée.
        retry = false,
    },
}
