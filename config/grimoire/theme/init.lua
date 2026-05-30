require("theme.palette")
require("theme.tokens")

Theme = {
    palette = Palette,
    tokens = Tokens,
}

require("theme.exporters.waybar")
require("theme.exporters.wlogout")
