local Layers = {}

Layers.developer = {
    enabled = false,

    profiles = {
        python = {
            name = "Python Developer",
            tools = {
                "python",
                "pip",
                "venv",
                "git",
                "lazygit",
            },
        },

        web = {
            name = "Web Developer",
            tools = {
                "nodejs",
                "npm",
                "git",
                "lazygit",
            },
        },

        fullstack = {
            name = "Full Stack Developer",
            tools = {
                "python",
                "nodejs",
                "npm",
                "git",
                "lazygit",
            },
        },
    },
}

Layers.containers = {
    enabled = false,

    choices = {
        "docker",
        "podman",
        "none",
    },
}

Layers.virtualization = {
    enabled = false,

    choices = {
        "virt-manager",
        "gnome-boxes",
        "none",
    },
}

return Layers
