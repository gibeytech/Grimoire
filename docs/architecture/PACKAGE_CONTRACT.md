# PACKAGE_CONTRACT.md

# Grimoire V3 — Package Contract

Version : 3.0 RC0

Statut : Fondation

---

# Objectif

Le Package Contract décrit les logiciels nécessaires à un profil.

Il constitue une couche d'abstraction entre le profil et le gestionnaire de paquets.

---

# Responsabilités

Le Package Contract décrit :

- les logiciels ;
- leur source ;
- leur gestionnaire ;
- leurs dépendances éventuelles.

---

# Ce que le Package Contract ne fait jamais

Il ne doit jamais :

- installer un logiciel ;
- modifier le système ;
- déployer des fichiers.

---

# Exemples

```
kitty
↓

pacman

↓

official
```

```
obsidian
↓

aur
```

Demain :

```
flatpak

snap

nix
```

sans modifier les profils.

---

# Invariants

Les profils ne connaissent jamais le gestionnaire de paquets.

Ils décrivent uniquement leurs besoins.

---

# Résumé

Le Package décrit les logiciels.

Il ne les installe jamais.
