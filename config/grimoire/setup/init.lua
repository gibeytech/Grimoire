local Setup = {}

--[[
Grimoire Setup Layer

Responsabilité :
- guider l'utilisateur
- détecter l'environnement
- collecter les choix
- préparer un plan d'installation
- déléguer au Packaging Layer
- déléguer à l'Install Engine

Cette couche ne doit pas :
- contenir le catalogue de paquets
- installer directement les paquets
- remplacer l'Install Engine
]]

Setup.detect = require("setup.detect")
Setup.compatibility = require("setup.compatibility")
Setup.profile = require("setup.profile")

function Setup.run()
    print("")
    print("===================================")
    print("      Bienvenue dans Grimoire")
    print("===================================")
    print("")

    local system = Setup.detect.run()

    print("Analyse système terminée")
    print("")

    print("Session : " .. tostring(system.session))
    print("Desktop : " .. tostring(system.desktop))
    print("")

    local report = Setup.compatibility.evaluate(system)

    print("Compatibilité Grimoire : " .. report.score .. "%")
    print("Niveau : " .. report.level)
    print("")

    local profile = Setup.profile.select()

    return {
        system = system,
        compatibility = report,
        profile = profile,
    }
end

return Setup
