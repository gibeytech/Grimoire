# EXECUTOR.md

# Grimoire V3 — Executor

## Statut

RC1-08

## Objectif

L'Executor orchestre l'installation Grimoire V3.

Il ne doit pas contenir la logique métier de chaque étape.

Il appelle les managers dans un ordre défini, collecte leurs résultats, puis retourne un résultat global.

## Chaîne actuelle

```text
InstallationPlan
→ Executor
→ PackageManager
→ ServiceManager
→ ShellManager
→ AssetManager
→ DeployManager
→ ExecutionResult[]
