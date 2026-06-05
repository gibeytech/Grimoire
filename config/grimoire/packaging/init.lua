local Packaging = {}

Packaging.catalogue = require("packaging.catalogue")
Packaging.profiles = require("packaging.profiles")
Packaging.layers = require("packaging.layers")

Packaging.core = require("packaging.core")
Packaging.desktop = require("packaging.desktop")
Packaging.display_manager = require("packaging.display_manager")

Packaging.setup = require("packaging.setup")

return Packaging
