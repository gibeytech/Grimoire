# CONFIG_SETUP_SPEC.md

# Configuration Setup Specification

## Pourquoi ce document existe

Ce document définit le fonctionnement de `config.setup()`.

L'objectif de `config.setup()` est de représenter une installation Grimoire de manière simple, cohérente et reproductible.

Il constitue le point d'entrée principal du Packaging Layer.

---

# Philosophie

Grimoire privilégie la simplicité.

La complexité ne doit apparaître que lorsque l'utilisateur la demande explicitement.

Les profils officiels doivent pouvoir être représentés par une configuration minimale.

Les profils personnalisés peuvent exposer l'ensemble des options disponibles.

---

# Structure générale

Une installation Grimoire est composée de quatre éléments :

```text
Base
↓
Profil
↓
Layers
↓
Choix utilisateur
```

---

# Base

La base est installée systématiquement.

Elle représente le socle minimal nécessaire au fonctionnement de Grimoire.

## Outils système

* Git
* OpenSSH

## Desktop Core

* Hyprland
* Waybar
* Rofi
* SwayNC
* Hyprlock
* Hypridle

La Base ne peut pas être désactivée.

---

# Profils

Les profils définissent l'expérience utilisateur.

## Profils officiels

* beginner
* advanced
* custom

---

# Profil Débutant

Objectif :

Installation immédiate.

Aucune personnalisation requise.

Exemple :

```lua
config.setup({
    profile = "beginner"
})
```

Grimoire applique automatiquement toutes les recommandations officielles.

---

# Profil Avancé

Objectif :

Permettre quelques choix importants.

Exemple :

```lua
config.setup({
    profile = "advanced"
})
```

Certaines catégories peuvent être personnalisées.

Le reste utilise les recommandations Grimoire.

---

# Profil Personnalisé

Objectif :

Contrôle complet de l'installation.

Exemple :

```lua
config.setup({
    profile = "custom"
})
```

Toutes les catégories du catalogue deviennent configurables.

---

# Layers

Les Layers ajoutent des fonctionnalités spécialisées.

Ils sont indépendants du profil.

Un utilisateur peut combiner librement :

* Débutant + Developer Layer
* Avancé + Container Layer
* Personnalisé + Virtualization Layer

---

# Layers prévus

## Developer Layer

Profils :

* Python Developer
* Web Developer
* Rust Developer
* Go Developer
* Java Developer
* Full Stack Developer
* Custom Developer

---

## Container Layer

Choix :

* Docker
* Podman
* Aucun

---

## Virtualization Layer

Choix :

* Virt-Manager
* GNOME Boxes
* Aucun

---

## Homelab Layer

Prévu pour une version future.

---

# Configuration minimale

Les profils officiels doivent fonctionner avec une configuration minimale.

Exemples :

```lua
config.setup({
    profile = "beginner"
})
```

```lua
config.setup({
    profile = "advanced"
})
```

---

# Configuration avancée

Les profils personnalisés permettent d'exprimer explicitement les choix utilisateur.

Exemple conceptuel :

```lua
config.setup({
    profile = "custom",

    layers = {
        developer = true,
        containers = true,
        virtualization = false
    },

    applications = {
        terminal = "ghostty",
        browser = "firefox",
        editor = "zed"
    }
})
```

Cette syntaxe est présentée à titre illustratif.

La structure définitive sera validée lors de l'implémentation.

---

# Règles de conception

## Simplicité avant tout

Une installation standard doit nécessiter le moins de décisions possible.

---

## Progressivité

Les options avancées ne doivent apparaître qu'aux utilisateurs qui les demandent.

---

## Reproductibilité

Une configuration doit permettre de reconstruire un environnement complet.

---

## Lisibilité

La configuration doit rester compréhensible même plusieurs mois après sa création.

---

# Vision long terme

À terme, `config.setup()` doit devenir le contrat principal entre :

* l'utilisateur ;
* le catalogue ;
* les profils ;
* les layers ;
* l'installateur.

Toute installation Grimoire doit pouvoir être représentée, sauvegardée et reconstruite à partir d'une configuration unique.
