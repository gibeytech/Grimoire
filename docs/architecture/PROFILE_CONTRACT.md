# PROFILE_CONTRACT.md

# Grimoire V3 — Profile Contract

Version : 3.0 RC0

Statut : Fondation

---

# Objectif

Un Profile décrit une expérience utilisateur.

Il ne contient aucune logique d'installation.

Il décrit uniquement ce qui compose un environnement.

---

# Responsabilités

Un Profile définit :

- les dotfiles ;
- les packages ;
- les thèmes ;
- les assets ;
- les services ;
- les modules utilisés.

---

# Ce que le Profile ne fait jamais

Un Profile ne doit jamais :

- installer un logiciel ;
- copier des fichiers ;
- modifier le système ;
- lancer un script ;
- prendre une décision technique.

---

# Dépendances

Le Profile dépend uniquement des contrats :

- Package ;
- Deploy.

Il est consommé par l'Installer.

---

# Invariants

Un Profile est :

- déclaratif ;
- indépendant ;
- versionnable ;
- reproductible.

---

# Résumé

Le Profile décrit.

Il n'exécute jamais.
