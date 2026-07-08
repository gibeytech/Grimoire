# CORE_V3.md

# Grimoire V3 — Architecture du Core

Version : 0.1

Statut : Fondation

---

# Objectif

Le Core est le cerveau de Grimoire.

Il connaît :

- les profils
- les manifestes
- les configurations
- les modèles métier

Le Core ne réalise jamais directement une installation.

Son rôle est de fournir des objets cohérents au reste du projet.

---

# Philosophie

Le Core applique une séparation stricte des responsabilités.

Chaque composant possède une mission unique.

Cette organisation permet :

- une architecture modulaire ;
- une maintenance simplifiée ;
- une forte évolutivité ;
- une meilleure testabilité.

---

# Architecture générale

```text
profiles/
        │
        ▼
 Manifest.lua
        │
        ▼
 ProfileLoader
        │
        ▼
 Profile
        │
        ▼
 Installer Builder
        │
        ▼
 InstallationPlan
        │
   ┌────┴─────┐
   ▼          ▼
Preview   Executor
```

---

# Les responsabilités

## Manifest

Le manifeste décrit un profil.

Il ne contient aucune logique.

Il référence simplement les différents éléments qui composent un profil.

Exemple :

- nom
- version
- description
- fichiers de configuration

---

## ProfileLoader

Le ProfileLoader est responsable du chargement.

Il :

- localise un profil ;
- charge les fichiers Lua ;
- construit un objet Profile.

Il ne réalise aucune validation métier.

Il ne réalise aucune installation.

---

## Profile

Le Profile représente un profil Grimoire.

Il constitue le modèle métier officiel du projet.

Le reste du Core ne manipule jamais directement les tables Lua.

Il manipule exclusivement un objet Profile.

L'API actuelle expose notamment :

- getId()
- getName()
- getVersion()
- getDescription()
- getRoot()
- getPackages()
- getServices()
- getShell()
- getTheme()
- getAssets()

Cette API pourra évoluer sans impacter les autres composants.

---

## Builder

Le Builder transforme un Profile en InstallationPlan.

Il prépare les données nécessaires à l'installation.

Il ne lance aucune commande système.

Il ne modifie jamais le système.

---

## InstallationPlan

L'InstallationPlan représente le résultat du Builder.

Il contient l'ensemble des informations nécessaires à une installation.

Il devient l'unique source de vérité pour les étapes suivantes.

---

## Preview

La Preview affiche le contenu d'un InstallationPlan.

Son objectif est de permettre à l'utilisateur de vérifier les choix avant installation.

Elle ne modifie jamais le système.

---

## Executor

L'Executor applique un InstallationPlan.

Il réalise effectivement :

- l'installation des paquets ;
- l'activation des services ;
- le déploiement des configurations.

L'Executor ne connaît jamais directement les profils.

---

# Séparation des responsabilités

Le Core ne doit jamais :

- installer un paquet ;
- appeler pacman ;
- créer un lien symbolique ;
- copier des fichiers ;
- modifier le système.

Ces responsabilités appartiennent exclusivement à l'Installer et au Deploy.

---

# Architecture globale de Grimoire

```text
Grimoire
│
├── core/
│   ├── loader/
│   ├── model/
│   ├── resolver/
│   └── validator/
│
├── installer/
│   ├── builder.lua
│   ├── preview.lua
│   └── executor.lua
│
├── deploy/
│
├── profiles/
│
└── shell/
```

---

# Principes fondamentaux

Le Core est indépendant.

L'Installer dépend du Core.

Le Deploy dépend de l'Installer.

Le Shell est indépendant du Core.

Cette hiérarchie garantit que chaque couche possède une responsabilité claire.

---

# Vision

Le Core doit rester :

- simple ;
- lisible ;
- testable ;
- extensible.

L'ajout d'un nouveau profil ne doit nécessiter aucune modification du moteur d'installation.

L'ajout d'un nouveau Layer ne doit nécessiter aucune modification du Core.

Le Core constitue la fondation technique de Grimoire V3.
