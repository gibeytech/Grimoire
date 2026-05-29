hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

hl.bind(
	"SHIFT + Print",
	hl.dsp.exec_cmd('grim -g "$(slurp)" ~/Pictures/$(date +%Y%m%d_%H%M%S).png')
)

hl.bind("SUPER + Print", hl.dsp.exec_cmd("grim - | wl-copy"))
