hl.exec_cmd("swaync")

hl.exec_cmd(
    "quickshell --no-duplicate "
        .. "-p $HOME/.config/grimoire-shell"
)

hl.exec_cmd("hypridle")

hl.exec_cmd(
    "wl-paste --type text "
        .. "--watch cliphist store"
)

hl.exec_cmd(
    "wl-paste --type image "
        .. "--watch cliphist store"
)
