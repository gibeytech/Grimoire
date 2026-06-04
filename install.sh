#!/usr/bin/env bash

set -euo pipefail

echo "═══════════════════════════════════"
echo "        Bienvenue dans Grimoire"
echo "═══════════════════════════════════"
echo
echo "Cet assistant préparera l'installation"
echo "et la configuration de Grimoire V2."
echo
echo "Aucune modification système ne sera"
echo "effectuée dans cette version squelette."
echo

read -rp "Continuer ? [O/n] " answer

case "${answer:-O}" in
    O|o|Y|y|"")
        echo
        echo "Analyse bootstrap..."
        ;;
    *)
        echo "Installation annulée."
        exit 0
        ;;
esac

echo
echo "Vérification des prérequis :"

for cmd in git lua; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✓ $cmd détecté"
    else
        echo "✗ $cmd manquant"
    fi
done

echo
echo "Squelette install.sh validé."
echo "Prochaine étape : brancher config.setup()."
