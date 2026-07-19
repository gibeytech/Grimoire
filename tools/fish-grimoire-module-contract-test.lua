print(
    "== Fish Grimoire RC4-D10B2 "
        .. "Module Contract Test =="
)

local path =
    "config/fish/grimoire.fish"

local file = assert(io.open(path, "rb"))
local content = file:read("*a")
file:close()

local function contains(value)
    return content:find(
        value,
        1,
        true
    ) ~= nil
end

assert(
    contains(
        "if status is-interactive"
    )
)

assert(
    contains(
        "functions -e fish_greeting"
    )
)

assert(
    contains(
        "starship init fish | source"
    )
)

assert(
    contains(
        'set -gx EDITOR nvim'
    )
)

assert(
    contains(
        'set -gx BROWSER brave'
    )
)

assert(
    contains(
        'contains -- "$HOME/.local/bin" $PATH'
    )
)

assert(
    not content:find(
        "set%s+%-U"
    )
)

assert(
    not content:find(
        "set%s+%-Ux"
    )
)

assert(
    not contains("fish_add_path")
)

assert(
    not contains(
        "source /usr/share/"
            .. "cachyos-fish-config/"
            .. "cachyos-config.fish"
    )
)

local ok, reason, code =
    os.execute(
        "fish -n "
            .. path
    )

assert(
    ok == true
        or ok == 0
        or code == 0,
    "fish -n a échoué : "
        .. tostring(reason)
        .. "/"
        .. tostring(code)
)

print("")
print(
    "RC4-D10B2 OK : le module est "
        .. "syntaxiquement valide, indépendant "
        .. "de CachyOS et n’utilise aucune "
        .. "variable universelle."
)
