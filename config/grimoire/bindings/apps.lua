local mainMod = "SUPER"

hl.bind(
    mainMod .. " + Return",
    hl.dsp.exec_cmd(Apps.terminal)
)

hl.bind(
    mainMod .. " + R",
    hl.dsp.exec_cmd(Apps.launcher)
)

hl.bind(
    mainMod .. " + E",
    hl.dsp.exec_cmd(Apps.fileManager)
)

hl.bind(
    mainMod .. " + Space",
    hl.dsp.exec_cmd(Apps.launcher)
)

hl.bind(
    mainMod .. " + B",
    hl.dsp.exec_cmd(Apps.browser)
)
