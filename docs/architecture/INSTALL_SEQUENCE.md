# INSTALL_SEQUENCE.md

# Grimoire V3 — Installation Sequence

Version : 3.0 RC0

Statut : Fondation

---

# Séquence officielle

```
Machine vierge
       │
       ▼
Bootstrap
       │
       ▼
Installer
       │
       ├────────► Chargement du Profile
       │
       ├────────► Résolution des Packages
       │
       ├────────► Installation des logiciels
       │
       ├────────► Deploy
       │
       ▼
Configuration finale
       │
       ▼
Premier démarrage
       │
       ▼
Grimoire Shell
```

---

# Ordre d'exécution

1. Bootstrap
2. Installer
3. Profile
4. Package
5. Installation des logiciels
6. Deploy
7. Validation
8. Premier lancement

---

# Principes

Chaque étape possède une responsabilité unique.

Une étape ne peut jamais exécuter la responsabilité d'une autre.

Toute erreur interrompt immédiatement la séquence.

---

# Objectif

Garantir une installation :

- reproductible ;
- déterministe ;
- modulaire ;
- indépendante des profils ;
- indépendante des interfaces utilisateur.
