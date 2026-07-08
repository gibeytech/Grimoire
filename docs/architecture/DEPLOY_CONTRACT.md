# DEPLOY_CONTRACT.md

# Grimoire V3 — Deploy Contract

Version : 3.0 RC0

Statut : Fondation

---

# Objectif

Le Deploy applique une configuration sur le système.

Il est responsable du déploiement des fichiers, des liens symboliques et des ressources communes.

Le Deploy ne décide jamais quoi déployer.

---

# Responsabilités

Le Deploy est responsable de :

- copier les fichiers ;
- créer les liens symboliques ;
- sauvegarder les fichiers existants ;
- restaurer un état précédent si nécessaire ;
- garantir un déploiement cohérent.

---

# Entrées

Le Deploy reçoit :

- un profil ;
- une liste de ressources ;
- une stratégie de déploiement.

---

# Sorties

À la fin du Deploy :

- les fichiers sont en place ;
- les liens sont créés ;
- la configuration est opérationnelle.

---

# Ce que le Deploy ne fait jamais

Le Deploy ne doit jamais :

- installer un logiciel ;
- choisir un profil ;
- modifier un package ;
- lancer le Shell ;
- prendre une décision métier.

---

# Dépendances

Le Deploy dépend uniquement de l'Installer.

Il ne dialogue jamais directement avec les profils.

---

# Invariants

Le Deploy doit être :

- reproductible ;
- idempotent ;
- réversible autant que possible.

---

# Résumé

Le Deploy applique.

Il ne décide jamais.
