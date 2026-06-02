# INSTALLER.md

# Architecture de l'installateur Grimoire

## Pourquoi ce document existe

Ce document décrit l'expérience utilisateur du futur installateur Grimoire.

L'objectif n'est pas de détailler l'implémentation technique.

L'objectif est de définir le parcours utilisateur.

---

# Philosophie

L'installateur doit être :

* simple
* progressif
* compréhensible
* reproductible

La complexité ne doit apparaître que lorsque l'utilisateur la demande.

---

# Parcours général

```text
Bienvenue

↓

Choix du profil

↓

Choix des Layers

↓

Personnalisation

↓

Résumé

↓

Installation
```

---

# Étape 1 — Bienvenue

Présentation rapide de Grimoire.

Objectifs :

* expliquer la philosophie du projet ;
* rassurer l'utilisateur ;
* présenter les trois profils.

---

# Étape 2 — Choix du profil

Profils disponibles :

## Débutant

Installation basée sur les recommandations Grimoire.

Peu ou pas de questions supplémentaires.

---

## Avancé

Quelques choix importants sont proposés.

Exemples :

* terminal
* navigateur
* éditeur
* gestionnaire de fichiers
* suite bureautique

---

## Personnalisé

Accès complet au catalogue Grimoire.

Toutes les catégories deviennent configurables.

---

# Étape 3 — Choix des Layers

Les Layers sont indépendants du profil.

Ils permettent d'ajouter des capacités spécifiques.

---

## Developer Layer

Profils disponibles :

* Python Developer
* Web Developer
* Rust Developer
* Go Developer
* Java Developer
* Full Stack Developer
* Custom Developer

---

## Container Layer

Choix disponibles :

* Docker
* Podman
* Aucun

---

## Virtualization Layer

Choix disponibles :

* Virt-Manager
* GNOME Boxes
* Aucun

---

## Homelab Layer

Prévu pour une version future.

---

# Étape 4 — Personnalisation

Cette étape dépend du profil sélectionné.

---

## Débutant

Aucune personnalisation supplémentaire.

---

## Avancé

Personnalisation limitée aux catégories principales.

---

## Personnalisé

Accès complet au catalogue.

Toutes les catégories peuvent être modifiées.

---

# Étape 5 — Résumé

Présentation de la configuration finale.

Exemple :

Profil :

* Avancé

Layers :

* Developer Layer
* Container Layer

Applications :

* Ghostty
* Firefox
* Neovim
* Thunar

L'utilisateur valide ou revient en arrière.

---

# Étape 6 — Installation

Création de la configuration finale.

Génération de :

config.setup()

Installation des composants sélectionnés.

Application des configurations.

---

# Vision long terme

À terme, l'installateur devra être capable de :

* générer une configuration reproductible ;
* reconstruire un environnement complet ;
* partager des profils ;
* importer des configurations existantes ;
* servir de point d'entrée principal à Grimoire.
