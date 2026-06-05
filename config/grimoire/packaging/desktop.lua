local Desktop = {}

Desktop.packages = {
    -- Portals / intégration desktop
    {
        name = "XDG Desktop Portal",
        package = "xdg-desktop-portal",
    },

    {
        name = "XDG Desktop Portal Hyprland",
        package = "xdg-desktop-portal-hyprland",
    },

    {
        name = "XDG Desktop Portal GTK",
        package = "xdg-desktop-portal-gtk",
    },

    -- Polkit
    {
        name = "Polkit",
        package = "polkit",
    },

    {
        name = "Hyprpolkitagent",
        package = "hyprpolkitagent",
    },

    -- Audio
    {
        name = "PipeWire",
        package = "pipewire",
    },

    {
        name = "WirePlumber",
        package = "wireplumber",
    },

    {
        name = "PipeWire Pulse",
        package = "pipewire-pulse",
    },

    -- Réseau
    {
        name = "NetworkManager",
        package = "networkmanager",
    },

    -- Bluetooth
    {
        name = "BlueZ",
        package = "bluez",
    },

    {
        name = "BlueZ Utils",
        package = "bluez-utils",
    },

    -- Support Wayland GTK / Qt
    {
        name = "Qt5 Wayland",
        package = "qt5-wayland",
    },

    {
        name = "Qt6 Wayland",
        package = "qt6-wayland",
    },

    {
        name = "GTK 3",
        package = "gtk3",
    },

    {
        name = "GTK 4",
        package = "gtk4",
    },
}

return Desktop
