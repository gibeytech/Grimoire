local desktop = Config.desktop

hl.config({
    input = desktop.input,

    general = {
        gaps_in = desktop.general.gaps_in,
        gaps_out = desktop.general.gaps_out,

        border_size = desktop.general.border_size,

        col = {
            active_border = desktop.general.active_border,
            inactive_border = desktop.general.inactive_border,
        },

        resize_on_border = desktop.general.resize_on_border,
        allow_tearing = desktop.general.allow_tearing,
        layout = desktop.general.layout,
    },

    decoration = desktop.decoration,

    animations = desktop.animations,
})

hl.gesture(desktop.gesture)

for _, device in ipairs(desktop.devices) do
    hl.device(device)
end
