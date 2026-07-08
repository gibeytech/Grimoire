# ASSET_MANIFEST.md

# Grimoire V3 — Asset Manifest

Version : 3.0 RC0

---

# Objectif

Décrire les ressources statiques.

---

# Exemple

```yaml
id: wallpapers

type: wallpaper

files:

  - grimoire.png

  - obsidian.png

destination:

  ~/.local/share/grimoire/wallpapers
```

Le manifeste décrit les ressources.

Le Deploy décide où elles sont copiées.
