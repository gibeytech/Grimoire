# ARCHITECTURE_GRIMOIRE_REPO.md

# Grimoire — Architecture cible du dépôt principal

Date : 2026-07-08  
Statut : proposition initiale

## Rôle du dépôt

Le dépôt `Grimoire` est le cœur opérationnel du projet.

Il ne contient pas le Book.
Il ne contient pas directement le Shell.
Il orchestre l'installation, les profils, les scripts, les thèmes et les configurations de référence.

## Architecture cible

```text
Grimoire/
├── bootstrap/
│   └── rc0/
├── installer/
├── profiles/
│   ├── beginner/
│   ├── advanced/
│   ├── creator/
│   └── gibeytech/
├── rc/
│   └── rc0/
├── scripts/
├── themes/
├── assets/
├── docs/
│   └── rc0/
└── legacy/
