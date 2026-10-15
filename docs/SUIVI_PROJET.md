# LAST HAVEN — Suivi du projet

Dernière mise à jour : 2026-10-15 · Phase courante : **Mission 1 (analyse) — en attente de validation**

## Légende des statuts

| Statut | Signification |
|---|---|
| ⬜ Non commencé | — |
| 🟦 En cours | Travail en cours |
| 🟨 Écrit, non exécuté | Code rédigé, pas encore lancé dans Godot |
| 🟧 Vérifié automatiquement | Lint + chargement headless + tests unitaires verts |
| ✅ **Validé** | Exécuté **et joué** par le développeur, conforme aux critères d'acceptation |

> Règle : une fonctionnalité n'est **jamais** marquée ✅ sans avoir été exécutée et jouée. 🟧 n'est pas ✅.

## Fonctionnalités validées

_Aucune pour l'instant — aucun code de jeu n'a été écrit._

## Mission 1 — Analyse préalable

| Point | Statut |
|---|---|
| Faisabilité | 🟨 rédigée (`PLAN_INITIAL.md` §1) — en attente de validation |
| Recommandation de moteur | 🟨 rédigée (§2) — en attente de validation |
| Structure des dossiers | 🟨 rédigée (§3) |
| Dépendances | 🟨 rédigées (§4) |
| Définition du MVP | 🟨 rédigée (§5) |
| Étapes de développement | 🟨 rédigées (§6) |
| Configuration Claude Code + Godot sur Windows | 🟨 rédigée (§7) ; commandes d'installation Claude Code vérifiées dans la doc officielle |
| Difficultés techniques | 🟨 rédigées (§8) |

## Journal des décisions

| # | Décision | Statut |
|---|---|---|
| D1 | Moteur : Godot 4 + GDScript typé | ⏳ à valider |
| D2 | Dépôt dédié `last-haven` | ⏳ à valider |
| D3 | Développement en local sur Windows | ⏳ à valider |
| D4 | Pas de collision joueur↔joueur en MVP | ⏳ à valider |
| D5 | Sauvegarde du camp locale en MVP | ⏳ à valider |
| D6 | Code en anglais, textes en français (traduction Godot) | ⏳ à valider |
| D7 | Configuration machine du développeur | ⏳ en attente d'information |
| D8 | Recettes et composants de départ | ⏳ à valider |

## Avancement par phase

| Phase | Contenu | Statut |
|---|---|---|
| 0 | Mise en place (Godot, Git, Claude Code, lint, tests) | ⬜ |
| 1 | Vertical slice solo (jalons 1.0 → 1.8) | ⬜ |
| 2 | Premier multijoueur (prototype réseau, 2 → 4 joueurs) | ⬜ |
| 3 | Gameplay PvP (couverture, réanimation, tickets, objectifs, crafting complet, récompense de série) | ⬜ |
| 4 | Communauté (camp, survivants, provisions, sauvegarde) | ⬜ |
| 5 | Polish | ⬜ |

## Limites connues de l'environnement (session de planification)

- Environnement cloud Linux : Godot 4 non installable (hôtes de téléchargement bloqués par la politique réseau) ; aucun test d'exécution possible ici.
- Seule la vérification statique du GDScript (gdtoolkit via pip) est disponible ici.
- Les détails d'API Godot du plan sont à confirmer sur la documentation de la version retenue (site de doc injoignable depuis cet environnement).

## Registre des risques (résumé — détail dans `PLAN_INITIAL.md` §8)

| Risque | Gravité | Atténuation |
|---|---|---|
| Netcode autoritaire d'un TPS (prédiction, lag compensation) | Élevée | Prototype réseau isolé (2.0) avant le contenu ; tests de latence et de client malveillant |
| Volume d'animations | Élevée | Doublures en MVP, logique indépendante des animations, exécution reportée |
| Dérive de périmètre | Élevée | Liste de coupe, une phase à la fois, gates de validation |
| « Le fun » non validable par l'IA | Moyenne | Jalons courts, playtests du développeur, gates de fun |
| Droits sur les assets | Moyenne | `ASSETS_LICENSES.md` obligatoire |
