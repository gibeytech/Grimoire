-- ============================================================
-- AUTOSTART
-- ============================================================

hl.on("hyprland.start", function()
	hl.exec_cmd("~/dotfiles/scripts/start-hyprpaper.sh")
	hl.exec_cmd("waybar")
	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("swaync")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)
