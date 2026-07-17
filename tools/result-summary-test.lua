local SummaryBuilder = require(
    "installer.summary_builder"
)

print("== SummaryBuilder RC4-D6 Test ==")

local results = {
    {
        manager = "packages",

        details = {
            runner = {
                command = "pacman",
            },
        },
    },

    {
        manager = "services",

        details = {
            service = "NetworkManager",
            operation = "enable",
        },
    },

    {
        manager = "services",

        details = {
            service = "sshd",
            operation = "disable",
        },
    },

    {
        manager = "shell",

        details = {
            runtime = "grimoire-shell",

            modules = {
                "bar",
                "hub",
                "launcher",
            },
        },
    },

    {
        manager = "assets",

        details = {
            operation = {
                type = "copy",
            },
        },
    },

    {
        manager = "deploy",

        details = {
            operation = {
                type = "copy",
            },
        },
    },

    {
        manager = "deploy",

        details = {
            operation = {
                type = "copy",
            },
        },
    },

    {
        manager = "deploy",

        details = {
            operation = {
                type = "symlink",
            },
        },
    },
}

local summary =
    SummaryBuilder.build(results)

assert(summary.packages.actions == 1)

assert(summary.services.enable == 1)
assert(summary.services.disable == 1)

assert(summary.shell.actions == 1)
assert(summary.shell.modules == 3)

assert(summary.assets.actions == 1)
assert(summary.assets.copies == 1)

assert(summary.deploy.actions == 3)
assert(summary.deploy.copies == 2)
assert(summary.deploy.symlinks == 1)

local total_copies =
    (summary.assets.copies or 0)
    + (summary.deploy.copies or 0)

local total_symlinks =
    (summary.assets.symlinks or 0)
    + (summary.deploy.symlinks or 0)

assert(total_copies == 3)
assert(total_symlinks == 1)

print(
    "Packages :",
    summary.packages.actions
)

print(
    "Services :",
    summary.services.enable,
    summary.services.disable
)

print(
    "Shell    :",
    summary.shell.modules
)

print(
    "Assets   :",
    summary.assets.copies
)

print(
    "Deploy   :",
    summary.deploy.copies,
    summary.deploy.symlinks
)

print(
    "Total FS :",
    total_copies,
    total_symlinks
)

print("")
print(
    "RC4-D6 OK : SummaryBuilder distingue "
        .. "les copies assets et deploy."
)
