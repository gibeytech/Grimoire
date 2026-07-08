# CORE_V3.md

# Grimoire V3 — Core Architecture

Version : 3.0 RC0

Statut : Fondation

---

# Vision

Grimoire n'est plus une collection de dotfiles.

Grimoire est une plateforme permettant de construire, installer et maintenir des environnements Linux cohérents, modulaires et reproductibles.

Le dépôt principal ne représente pas une configuration.

Il représente le **Core** de la plateforme.

Les expériences utilisateur sont apportées par les profils.

Les interfaces utilisateur sont apportées par Grimoire Shell.

---

# Objectifs

Le Core doit permettre de :

- construire une installation Grimoire complète ;
- installer différents profils sans modifier l'architecture ;
- gérer plusieurs stratégies de déploiement ;
- supporter plusieurs sources de paquets ;
- évoluer indépendamment des interfaces graphiques.

Le Core constitue le socle technique commun à toutes les installations.

---

# L'écosystème Grimoire

Grimoire est composé de plusieurs dépôts indépendants.

```
                 Grimoire-Book
                        │
                        ▼
               Documentation & Vision
                        │
                        ▼
                  Grimoire Core
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   Bootstrap        Profiles       Packages
        │               │               │
        └───────────────┼───────────────┘
                        ▼
                     Deploy
                        │
                        ▼
                Grimoire Shell
                        │
                        ▼
                  Machine finale
```

Chaque dépôt possède une responsabilité unique.

---

# Grimoire Book

Le Book constitue la source de vérité du projet.

Il contient :

- la vision ;
- les décisions d'architecture ;
- les roadmaps ;
- la documentation fonctionnelle ;
- les spécifications.

Il ne contient aucun code de production.

---

# Grimoire

Le dépôt principal contient le Core.

Il regroupe :

- Bootstrap ;
- Installer ;
- Deploy ;
- Profiles ;
- Packages ;
- Assets communs ;
- Scripts communs ;
- Documentation technique.

Le dépôt Grimoire ne contient aucune interface utilisateur.

---

# Grimoire Shell

Grimoire Shell est un projet indépendant.

Il fournit :

- la Bar ;
- le Hub ;
- les Panels ;
- les Popups ;
- les Providers ;
- le Runtime Quickshell.

Le Shell ne décide jamais :

- quels logiciels installer ;
- quel profil utiliser ;
- où déployer les fichiers.

Il consomme uniquement les informations produites par le Core.

---

# Machine de Référence

La Machine de Référence est la plateforme officielle de validation.

Elle permet de :

- tester le Core ;
- tester les profils ;
- tester les scripts ;
- tester le Shell ;
- valider les procédures d'installation ;
- produire la documentation officielle.

Une Release Candidate est toujours validée sur la Machine de Référence avant publication.

---

# Le Core

Le Core représente l'ensemble des composants communs à toutes les installations Grimoire.

Il constitue le socle de la plateforme.

Le Core ne contient :

- aucun choix utilisateur ;
- aucun workflow personnel ;
- aucune configuration spécifique à un profil.

Le Core fournit uniquement les briques nécessaires à la construction d'un environnement.

---

# Les composants du Core

Le Core repose sur cinq composants fondamentaux.

```
Bootstrap
Installer
Deploy
Profile
Package
```

Chaque composant possède un contrat indépendant.

---

# Responsabilités

## Bootstrap

Prépare une machine capable d'exécuter Grimoire.

---

## Installer

Orchestre l'installation complète.

---

## Deploy

Applique une configuration sur le système.

---

## Profile

Décrit une expérience utilisateur.

---

## Package

Décrit les logiciels nécessaires à un profil.

---

# Dépendances autorisées

L'architecture officielle est la suivante.

```
                  Installer
                 /    |    \
                /     |     \
               ▼      ▼      ▼
        Bootstrap  Profile  Package
                      │
                      ▼
                   Deploy
```

L'Installer est le seul composant autorisé à orchestrer les autres.

Aucune dépendance inverse n'est autorisée.

---

# Invariants

Les règles suivantes sont immuables.

Bootstrap ne connaît jamais les profils.

Installer ne copie jamais directement des fichiers.

Installer n'installe jamais directement un logiciel.

Deploy ne décide jamais quoi installer.

Deploy ne sélectionne jamais un profil.

Profile ne contient aucune logique d'exécution.

Package ne modifie jamais le système.

Chaque composant possède une responsabilité unique.

---

# Cycle officiel de développement

Grimoire est développé selon le cycle suivant.

```
Décision
      │
      ▼
Architecture
      │
      ▼
Documentation
      │
      ▼
Code
      │
      ▼
Validation
```

Aucune implémentation ne doit commencer avant la validation de son architecture.

---

# Objectif final

L'objectif de Grimoire V3 est de construire une plateforme durable.

L'ajout :

- d'un nouveau profil ;
- d'un nouveau gestionnaire de paquets ;
- d'une nouvelle stratégie de déploiement ;
- d'un nouveau Shell ;

ne doit jamais remettre en cause l'architecture du Core.

Cette indépendance constitue le fondement de Grimoire V3.
