-- ============================================================
-- MONITEURS
-- ============================================================

-- Écran principal (laptop) — en bas
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@60",
	position = "0x1200",
	scale = "1",
})

-- Second écran Iiyama — au-dessus
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1200@60",
	position = "0x0",
	scale = "1",
})
