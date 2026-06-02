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
        docker = {
            name = "Docker",
            packages = {
                "docker",
                "docker-compose",
            },
        },

        podman = {
            name = "Podman",
            packages = {
                "podman",
            },
        },

        none = {
            name = "Aucun",
            packages = {},
        },
    },
}

Layers.virtualization = {
    enabled = false,

    choices = {
        virt_manager = {
            name = "Virt-Manager",
            packages = {
                "virt-manager",
                "qemu-full",
                "libvirt",
                "dnsmasq",
                "bridge-utils",
            },
        },

        gnome_boxes = {
            name = "GNOME Boxes",
            packages = {
                "gnome-boxes",
            },
        },

        none = {
            name = "Aucun",
            packages = {},
        },
    },
}

return Layers
