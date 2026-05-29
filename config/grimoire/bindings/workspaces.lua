local mainMod = "SUPER"

local azerty_keys = {
	"code:10",
	"code:11",
	"code:12",
	"code:13",
	"code:14",
	"code:15",
	"code:16",
	"code:17",
	"code:18",
	"code:19",
}

for i, key in ipairs(azerty_keys) do
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
