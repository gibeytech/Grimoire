local Setup = {}

--[[
Grimoire setup layer

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

return Setup
