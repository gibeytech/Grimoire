# BOOTSTRAP_CONTRACT.md

# Grimoire V3 — Bootstrap Contract

Version : 3.0 RC0

Statut : Fondation

---

# Objectif

Le Bootstrap prépare une machine capable d'exécuter Grimoire.

Il constitue la première étape de toute installation.

Le Bootstrap ne construit pas un environnement utilisateur.

Il prépare uniquement le terrain.

---

# Responsabilités

Le Bootstrap est responsable de :

- vérifier le système hôte ;
- préparer les dépendances minimales ;
- installer les outils nécessaires au Core ;
- préparer l'environnement d'installation ;
- transmettre l'exécution à l'Installer.

Une fois terminé, le Bootstrap n'intervient plus.

---

# Ce que le Bootstrap ne fait jamais

Le Bootstrap ne doit jamais :

- installer un profil ;
- choisir un profil ;
- installer des applications utilisateur ;
- déployer des dotfiles ;
- modifier la configuration utilisateur ;
- lancer le Shell ;
- prendre une décision métier.

Toute logique fonctionnelle appartient à l'Installer.

---

# Entrées

Le Bootstrap reçoit :

- un système compatible ;
- le dépôt Grimoire ;
- les paramètres nécessaires à son exécution.

Il ne dépend d'aucun profil.

---

# Sorties

À la fin de son exécution :

- les outils nécessaires sont disponibles ;
- les prérequis sont validés ;
- l'Installer peut démarrer.

---

# Dépendances autorisées

Le Bootstrap peut utiliser :

- les scripts du Core ;
- les outils système ;
- les gestionnaires de paquets nécessaires à son propre fonctionnement.

Il ne dépend pas :

- des profils ;
- du Deploy ;
- du Shell.

---

# Contrat avec l'Installer

Le Bootstrap remet toujours la main à l'Installer.

Il ne poursuit jamais l'installation.

```
Bootstrap
      │
      ▼
 Installer
```

---

# Erreurs

Le Bootstrap doit interrompre immédiatement l'installation si :

- le système est incompatible ;
- une dépendance critique est absente ;
- un outil indispensable ne peut être installé ;
- les droits nécessaires sont insuffisants.

Aucun contournement automatique ne doit masquer une erreur critique.

---

# Invariants

Le Bootstrap est :

- déterministe ;
- reproductible ;
- idempotent autant que possible.

Deux exécutions successives doivent produire le même résultat.

---

# Évolutions futures

Le contrat Bootstrap doit permettre de supporter plusieurs systèmes compatibles.

Exemples :

- Arch Linux
- CachyOS
- EndeavourOS
- Fedora (à terme)

Cette évolution ne doit jamais nécessiter de modification des autres contrats.

---

# Résumé

Le Bootstrap prépare la machine.

Il ne prend aucune décision fonctionnelle.

Il remet systématiquement l'exécution à l'Installer.

Sa responsabilité est exclusivement de rendre le système prêt à recevoir Grimoire.
