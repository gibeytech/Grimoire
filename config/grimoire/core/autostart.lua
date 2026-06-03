hl.exec_cmd("swaync")
hl.exec_cmd("sh -c 'if ! pgrep -x waybar >/dev/null; then waybar >/dev/null 2>&1 & fi'")
hl.exec_cmd("hypridle")
hl.exec_cmd("wl-paste --type text --watch cliphist store")
hl.exec_cmd("wl-paste --type image --watch cliphist store")

