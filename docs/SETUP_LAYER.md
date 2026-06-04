# Grimoire V2 — SETUP_LAYER.md

## Objectif

Le Setup Layer est l'assistant d'installation de Grimoire.

Il guide l'utilisateur dans la construction de son environnement sans jamais imposer un choix.

Le Setup Layer ne contient aucune logique d'installation.

Son rôle est de :

* détecter ;
* informer ;
* proposer ;
* protéger ;
* résumer ;
* déléguer.

---

# Philosophie

Grimoire recommande.

L'utilisateur choisit.

Le Setup Layer doit toujours expliquer avant d'agir.

L'utilisateur doit comprendre :

* ce qui a été détecté ;
* ce qui est recommandé ;
* ce qui sera modifié ;
* ce qui sera sauvegardé.

---

# Position dans l'architecture

```text
install.sh
↓
Bootstrap Layer
↓
Setup Layer
↓
Packaging Layer
↓
Install Engine
↓
Runtime Grimoire
```

---

# Responsabilités

## Setup Layer

Responsable de :

* l'expérience utilisateur ;
* l'analyse de l'environnement ;
* les choix utilisateur ;
* les sauvegardes ;
* le résumé final.

Non responsable de :

* la résolution des paquets ;
* l'installation des paquets ;
* l'activation des services ;
* le déploiement technique.

Ces responsabilités appartiennent à l'Install Engine.

---

# Modules prévus

## init.lua

Point d'entrée principal.

Orchestre le déroulement complet du Setup Layer.

---

## detect.lua

Réalise une photographie du système.

Détecte :

* distribution ;
* session ;
* WM ;
* shell ;
* terminaux ;
* navigateurs ;
* éditeurs ;
* GPU ;
* laptop ;
* desktop ;
* VM ;
* configurations existantes.

Ne prend aucune décision.

---

## compatibility.lua

Interprète les résultats de détection.

Produit :

* un score de compatibilité ;
* un rapport lisible.

Ne modifie rien.

---

## backup.lua

Responsable des sauvegardes.

Fonctions :

* préparation ;
* affichage ;
* création ;
* rapport.

Principe :

Ne jamais casser un système existant.

---

## selection.lua

Interface de sélection utilisateur.

Affiche les choix préparés par le Packaging Layer.

Ne connaît pas la structure interne du catalogue.

---

## summary.lua

Affiche le résumé final.

Contient :

* composants sélectionnés ;
* sauvegardes prévues ;
* paquets ;
* actions futures.

Actions possibles :

* Installer
* Modifier
* Quitter

---

## deploy.lua

Prépare le plan d'installation.

Ne réalise aucune installation directement.

Transmet les informations à l'Install Engine.

---

# Flux simplifié

```text
Detect
↓
Compatibility
↓
Selection
↓
Summary
↓
Deploy
↓
Install Engine
```

---

# Règle fondamentale

Le Setup Layer est une couche d'orchestration.

Il ne doit jamais devenir :

* un catalogue ;
* un gestionnaire de paquets ;
* un moteur d'installation.

Son rôle est de guider l'utilisateur et de transmettre ses choix aux couches spécialisées.
