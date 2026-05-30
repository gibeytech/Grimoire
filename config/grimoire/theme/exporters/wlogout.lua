local css = string.format([[
@define-color background %s;
@define-color surface %s;
@define-color accent %s;
@define-color text %s;
@define-color danger %s;
]],
    Tokens.background,
    Tokens.surface,
    Tokens.accent,
    Tokens.text,
    Tokens.danger
)

local file = io.open(os.getenv("HOME") .. "/.config/wlogout/colors.css", "w")

if file then
    file:write(css)
    file:close()
end
