print(
    "== Fish Grimoire RC4-D10B2 "
        .. "Isolated Runtime Test =="
)

local function shell_quote(value)
    return "'"
        .. tostring(value):gsub(
            "'",
            "'\\''"
        )
        .. "'"
end

local function command_succeeded(command)
    local ok, _, code = os.execute(command)

    return ok == true
        or ok == 0
        or code == 0
end

local temporary_directory =
    os.tmpname()

os.remove(temporary_directory)

assert(
    command_succeeded(
        "mkdir -p -- "
            .. shell_quote(
                temporary_directory
                    .. "/config"
            )
    )
)

local script_path =
    temporary_directory
        .. "/runtime-test.fish"

local script =
    assert(io.open(script_path, "wb"))

assert(script:write([[
set greeting_before (
    functions fish_greeting 2>/dev/null |
        string collect
)

set ls_before (
    functions ls 2>/dev/null |
        string collect
)

source config/fish/grimoire.fish
source config/fish/grimoire.fish

test "$EDITOR" = "nvim"
or exit 10

test "$VISUAL" = "nvim"
or exit 11

test "$TERMINAL" = "kitty"
or exit 12

test "$BROWSER" = "brave"
or exit 13

test "$MANPAGER" = "nvim +Man!"
or exit 14

set local_bin_count 0

for path_entry in $PATH
    if test "$path_entry" = "$HOME/.local/bin"
        set local_bin_count (
            math "$local_bin_count + 1"
        )
    end
end

test "$local_bin_count" -eq 1
or exit 15

set greeting_after (
    functions fish_greeting 2>/dev/null |
        string collect
)

set ls_after (
    functions ls 2>/dev/null |
        string collect
)

# En mode non interactif, le module ne doit pas
# modifier les fonctions éventuellement fournies par Fish.
test "$greeting_after" = "$greeting_before"
or exit 16

test "$ls_after" = "$ls_before"
or exit 17

exit 0
]]))

assert(script:close())

local command =
    table.concat({
        "env",
        "HOME="
            .. shell_quote(
                temporary_directory
                    .. "/home"
            ),
        "XDG_CONFIG_HOME="
            .. shell_quote(
                temporary_directory
                    .. "/config"
            ),
        "fish --no-config",
        shell_quote(script_path),
    }, " ")

local ok, reason, code =
    os.execute(command)

local cleanup_ok =
    command_succeeded(
        "rm -rf -- "
            .. shell_quote(
                temporary_directory
            )
    )

assert(cleanup_ok == true)

assert(
    ok == true
        or ok == 0
        or code == 0,
    "Runtime Fish isolé en échec : "
        .. tostring(reason)
        .. "/"
        .. tostring(code)
)

print("")
print(
    "RC4-D10B2 OK : le module est "
        .. "idempotent et ne modifie aucune "
        .. "fonction interactive dans un "
        .. "shell non interactif."
)
