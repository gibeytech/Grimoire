local mainMod = "SUPER"

hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/dotfiles/scripts/wallpaper.sh"))

hl.bind(
	mainMod .. " + SHIFT + Q",
	hl.dsp.exec_cmd("wlogout --protocol layer-shell -b 5 -T 400 -B 400 --css ~/.config/wlogout/style.css")
)

hl.bind(
	mainMod .. " + L",
	hl.dsp.exec_cmd("/home/joe/dotfiles/scripts/lock.sh")
)
