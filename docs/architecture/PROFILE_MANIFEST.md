# PROFILE_MANIFEST.md

# Grimoire V3 — Profile Manifest

Version : 3.0 RC0

Statut : Fondation

---

# Objectif

Le Profile Manifest décrit entièrement un profil Grimoire.

Il est purement déclaratif.

Il ne contient aucune logique.

---

# Responsabilités

Le manifeste décrit :

- l'identité du profil ;
- les packages utilisés ;
- les dotfiles ;
- les thèmes ;
- les services ;
- le shell utilisé ;
- les modules activés.

---

# Exemple

```yaml
id: gibeytech

name: GibeyTech

version: 3.0

description: Profil de référence du projet

packages:
  - base
  - desktop
  - development

theme:
  grimoire

shell:
  grimoire-shell

services:
  - pipewire
  - networkmanager

modules:
  - bar
  - hub
  - notifications

dotfiles:
  source: dotfiles/
```

---

# Invariants

Le manifeste :

- est déclaratif ;
- ne contient aucun script ;
- ne contient aucune commande ;
- ne dépend pas du système.

Le Core interprète le manifeste.
