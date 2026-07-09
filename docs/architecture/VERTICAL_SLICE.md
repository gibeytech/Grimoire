# VERTICAL_SLICE.md

# Grimoire V3 — Vertical Slice

## Statut

RC1-10

## Objectif

Valider un premier parcours utilisateur complet sans installation réelle.

Le but n'est pas encore d'exécuter pacman, systemctl ou une copie de fichiers.

Le but est de vérifier que toute la chaîne V3 fonctionne de bout en bout.

## Chaîne validée

```text
install.sh
→ tools/installer-slice.lua
→ ProfileLoader
→ ProfileValidator
→ Builder
→ InstallationPlan
→ InstallationPlanValidator
→ Preview
→ Executor
→ Managers
→ ExecutionResult
→ Résumé final
