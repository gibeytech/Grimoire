#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export LUA_PATH="$ROOT_DIR/config/grimoire/?.lua;$ROOT_DIR/config/grimoire/?/init.lua;$ROOT_DIR/config/grimoire/?/?.lua;;"

TMP_LUA="$(mktemp)"
trap 'rm -f "$TMP_LUA"' EXIT

cat > "$TMP_LUA" <<'LUA'
local Setup = require("setup")
local Installer = require("installer")

local result = Setup.run()

local config = Installer.builder.build(result.profile)

print("")
print(Installer.preview.summary(config))
print("")

io.write("Installer Grimoire V2 alpha ? [o/N] ")
local answer = io.read()

if answer ~= "o" and answer ~= "O" and answer ~= "oui" and answer ~= "Oui" then
    print("")
    print("Installation annulée.")
    os.exit(0)
end

print("")
print("Lancement de l'installation alpha...")
print("")

local output = Installer.execute.install(config)

print(output)
print("")
print("Installation alpha terminée.")
print("")
print("Note : les paquets AUR sont seulement détectés pour l'instant.")
print("Note : le déploiement des dotfiles viendra dans une étape suivante.")
LUA

lua "$TMP_LUA"
