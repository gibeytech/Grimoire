local home =
    assert(
        os.getenv("HOME"),
        "Variable HOME absente"
    )

local grimoire_root =
    home .. "/.config/grimoire"

local required_paths = {
    grimoire_root .. "/?.lua",
    grimoire_root .. "/?/init.lua",
}

for _, lua_path in ipairs(required_paths) do
    if not package.path:find(
        lua_path,
        1,
        true
    ) then
        package.path =
            package.path
                .. ";"
                .. lua_path
    end
end

require("init")
