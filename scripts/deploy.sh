#!/usr/bin/env bash

set -euo pipefail

BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

CONFIGS=(
    fish
    hypr
    kitty
    rofi
    swaync
    waybar
    wlogout
    grimoire
)

echo ""
echo "Déploiement des configurations Grimoire"
echo ""

mkdir -p "$HOME/.config"

for config in "${CONFIGS[@]}"; do
    SOURCE="config/$config"
    TARGET="$HOME/.config/$config"

    if [ ! -d "$SOURCE" ]; then
        continue
    fi

    if [ -e "$TARGET" ]; then
        echo "Sauvegarde : $TARGET"
        mv "$TARGET" "${TARGET}.backup.${BACKUP_SUFFIX}"
    fi

    echo "Déploiement : $config"
    cp -r "$SOURCE" "$TARGET"
done

echo ""
echo "Déploiement terminé."
