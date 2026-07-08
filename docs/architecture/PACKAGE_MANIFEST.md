# PACKAGE_MANIFEST.md

# Grimoire V3 — Package Manifest

Version : 3.0 RC0

---

# Objectif

Décrire un ensemble logique de logiciels.

---

# Exemple

```yaml
id: desktop

packages:

  - kitty

  - thunar

  - brave

  - vlc

source:

  pacman
```

---

Le manifeste décrit uniquement les logiciels.

Le Core décide comment les installer.
