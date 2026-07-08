# INSTALLER_CONTRACT.md

# Grimoire V3 — Installer Contract

Version : 3.0 RC0

Statut : Fondation

---

# Objectif

L'Installer est l'orchestrateur de Grimoire.

Il coordonne l'ensemble de l'installation sans jamais réaliser lui-même les opérations spécialisées.

Sa responsabilité est uniquement de piloter les différents composants du Core.

---

# Responsabilités

L'Installer est responsable de :

- lancer le Bootstrap si nécessaire ;
- sélectionner le profil ;
- charger les définitions de packages ;
- déclencher le Deploy ;
- contrôler le déroulement de l'installation ;
- produire les journaux d'installation.

L'Installer ne réalise jamais directement le travail des autres composants.

---

# Flux général

```
Utilisateur
      │
      ▼
 Installer
      │
      ├────────► Bootstrap
      │
      ├────────► Profile
      │
      ├────────► Package
      │
      └────────► Deploy
```

---

# Entrées

L'Installer reçoit :

- la configuration d'installation ;
- le profil sélectionné ;
- les options utilisateur ;
- les paramètres du système.

---

# Sorties

À la fin de son exécution :

- le système est installé ;
- les fichiers sont déployés ;
- les applications sont installées ;
- le profil est opérationnel.

---

# Ce que l'Installer ne fait jamais

L'Installer ne doit jamais :

- copier des fichiers ;
- créer des liens symboliques ;
- installer directement des paquets ;
- contenir des dotfiles ;
- modifier un profil.

Toutes ces responsabilités sont déléguées.

---

# Dépendances autorisées

L'Installer peut communiquer uniquement avec :

- Bootstrap ;
- Profile ;
- Package ;
- Deploy.

Il constitue le point central de l'installation.

---

# Gestion des erreurs

L'Installer doit :

- arrêter immédiatement une erreur critique ;
- produire un journal lisible ;
- permettre un diagnostic rapide.

Il ne masque jamais une erreur.

---

# Invariants

L'Installer :

- ne possède aucune configuration spécifique à un profil ;
- reste indépendant des interfaces graphiques ;
- reste indépendant du Shell ;
- ne dépend pas d'une distribution particulière.

---

# Résumé

L'Installer orchestre.

Il ne configure pas.

Il ne déploie pas.

Il ne choisit pas comment fonctionnent les autres composants.

Il coordonne uniquement leur exécution.
