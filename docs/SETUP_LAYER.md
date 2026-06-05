# Grimoire V2 — SETUP_LAYER.md

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

# Flux simplifié

```text
Detect
↓
Compatibility
↓
Selection
↓
Deploy.preview()
↓
Summary
↓
Validation finale
↓
Backup
↓
Deploy.run()
↓
Install Engine
```

---

# Contrat des choix utilisateur

`selection.lua` produit un objet simple.

Il ne résout pas les paquets.

Il ne connaît pas les chemins de configuration.

Il ne prépare pas les sauvegardes.

Exemple :

```lua
choices = {
    terminals = {
        "kitty",
        "ghostty",
    },

    shell = "fish",
    browser = "brave",
    editor = "vscode",
    display_manager = "sddm",
}
```

Principe :

```text
choices = simple
plan = riche
```

---

# Contrat du plan

`deploy.lua` transforme les choix utilisateur en plan concret via :

```text
Deploy.preview()
```

Ce plan sert ensuite à :

* afficher le résumé final ;
* prévoir les sauvegardes ;
* transmettre les actions au moteur d'installation.

Structure minimale :

```lua
plan = {
    components = {},

    backups = {},

    packages = {
        official = {},
        aur = {},
    },
}
```

Exemple :

```lua
plan = {
    components = {
        {
            id = "fish",
            name = "Fish",
            package = "fish",
            config_path = "~/.config/fish",
        },
    },

    backups = {
        {
            component = "Fish",
            path = "~/.config/fish",
        },
    },

    packages = {
        official = {
            "fish",
        },

        aur = {},
    },
}
```

---

# Validation finale

Principe :

Aucune action ne doit être réalisée avant validation explicite de l'utilisateur.

Cette étape permet de confirmer :

* les composants sélectionnés ;
* les sauvegardes qui seront réalisées ;
* les paquets qui seront installés ;
* les modifications prévues.

Une fois la validation effectuée :

```text
Validation finale
↓
Backup
↓
Deploy.run()
```

Le système est alors protégé avant toute modification.

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

## selection.lua

Interface de sélection utilisateur.

Produit les choix utilisateur.

Ne connaît pas la structure interne du catalogue.

Ne résout pas les paquets.

Ne prépare pas les sauvegardes.

---

## deploy.lua

Prépare le plan d'installation.

Fonctions prévues :

* `preview()` prépare le plan sans agir ;
* `run()` transmet le plan final à l'Install Engine.

Ne réalise aucune installation directement.

---

## summary.lua

Affiche le résumé final.

Contient :

* composants sélectionnés ;
* sauvegardes prévues ;
* nombre de paquets officiels ;
* nombre de paquets AUR.

Actions possibles :

* Installer
* Modifier
* Quitter

---

## backup.lua

Responsable des sauvegardes.

Fonctions :

* préparation ;
* affichage ;
* création ;
* rapport.

Principe :

Ne jamais écraser une configuration existante sans sauvegarde.

`backup.lua` ne décide pas ce qui doit être sauvegardé.

Il exécute les sauvegardes prévues par le plan.

---

# Règle fondamentale

Le Setup Layer est une couche d'orchestration.

Il ne doit jamais devenir :

* un catalogue ;
* un gestionnaire de paquets ;
* un moteur d'installation.

Son rôle est de guider l'utilisateur et de transmettre ses choix aux couches spécialisées.
