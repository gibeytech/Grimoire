# MODULE_MANIFEST.md

# Grimoire V3 — Module Manifest

Version : 3.0 RC0

---

# Objectif

Décrire un module du Core ou du Shell.

---

# Exemple

```yaml
id: hub

version: 1.0

provider:

dependencies:

capabilities:

enabled:

description:
```

---

# Utilisation

Tous les modules Grimoire suivent le même contrat.

Le Core et Grimoire Shell peuvent interpréter un manifeste de manière identique.

Cette uniformité garantit une architecture cohérente entre les différents dépôts.
