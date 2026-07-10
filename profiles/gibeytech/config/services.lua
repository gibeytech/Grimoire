return {
    services = {
        {
            unit = "NetworkManager.service",
            operation = "enable",
            scope = "system",
        },
        {
            unit = "bluetooth.service",
            operation = "enable",
            scope = "system",
        },
        {
            unit = "pipewire.service",
            operation = "enable",
            scope = "user",
        },
        {
            unit = "wireplumber.service",
            operation = "enable",
            scope = "user",
        },
        {
            unit = "sddm.service",
            operation = "enable",
            scope = "system",
        },
        {
            unit = "sshd.service",
            operation = "disable",
            scope = "system",
        },
    },
}
