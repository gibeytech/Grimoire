local Installer = {}

Installer.builder = require("installer.builder")
Installer.validate = require("installer.validate")
Installer.preview = require("installer.preview")
Installer.report = require("installer.report")
Installer.execute = require("installer.execute")

return Installer
