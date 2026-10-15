# LAST HAVEN — Suivi du projet

Dernière mise à jour : 2026-10-15 · Phase courante : **Phase 1 — jalons 1.0 et 1.1 écrits, en attente de ton playtest**

## Légende des statuts

| Statut | Signification |
|---|---|
| ⬜ Non commencé | — |
| 🟦 En cours | Travail en cours |
| 🟨 Écrit, non exécuté | Code rédigé, jamais lancé |
| 🟧 Vérifié automatiquement | `python tools/check.py` vert : format, lint, chargement, tests, lancement headless |
| ✅ **Validé** | Exécuté **et joué** par le développeur, conforme aux critères d'acceptation |

> Règle : une fonctionnalité n'est **jamais** marquée ✅ sans avoir été jouée par toi. 🟧 n'est pas ✅ : la vérification automatique ne voit ni l'image, ni le « feeling ».

## Fonctionnalités validées (jouées)

_Aucune pour l'instant._ Le jalon 1.1 attend ton playtest (voir la check-list du README).

## Phase 0 — Mise en place

| Élément | Statut |
|---|---|
| Squelette du projet Godot 4 (`project.godot`, dossiers, `.gitignore`, `.gitattributes`, `.editorconfig`) | 🟧 |
| `CLAUDE.md` (règles + commandes), `.claude/settings.json` (liste blanche limitée) | 🟧 chargé sans erreur ; **non éprouvé sous Windows** |
| Format + lint GDScript (`gdtoolkit`) | 🟧 |
| Tests headless (runner maison, tests de physique) | 🟧 |
| `tools/check.py` — une commande pour tout vérifier | 🟧 testé aussi **en l'altérant volontairement** (erreur de syntaxe, régression de logique, scène cassée : détectés) |
| Installation de Godot, Git, Claude Code et `gdtoolkit` sur ta machine Windows | ⏳ **à faire par toi** (README + plan §7) |
| Épingler la version exacte de Godot que tu utilises | ⏳ à faire quand tu l'auras installée |

## Phase 1 — Vertical slice solo

| Jalon | Contenu | Statut | Ce qui est vérifié / ce qui reste |
|---|---|---|---|
| 1.0 | Squelette, outillage, scène de démarrage | 🟧 | Tout charge, le jeu tourne 120 images en headless sans erreur ni avertissement |
| 1.1 | Arène greybox + marche / sprint / accroupi / saut + caméra épaule minimale | 🟧 **non joué** | 15 tests de physique verts (vitesses, accroupi, passage sous la poutre, saut, atterrissage, orientation). **Non vérifié : le rendu, la caméra, le « poids » du mouvement, les saccades** |
| 1.2 | Caméra TPS complète (inversion d'épaule, zoom de visée) | ⬜ | Attend ton retour sur 1.1 |
| 1.3 | Arme hitscan, recul, rechargement | ⬜ | |
| 1.4 | Santé / dégâts / cibles à zones | ⬜ | |
| 1.5 | Caisse de loot + 3 composants | ⬜ | |
| 1.6 | Crafting + kit de soin | ⬜ | |
| 1.7 | HUD | ⬜ | |
| 1.8 | Correctifs, build `.exe`, gate de fun | ⬜ | |

## Phases suivantes

| Phase | Contenu | Statut |
|---|---|---|
| 2 | Premier multijoueur (prototype réseau, 2 → 4 joueurs) | ⬜ |
| 3 | Gameplay PvP (couverture, réanimation, tickets, objectifs, crafting complet, récompense de série) | ⬜ |
| 4 | Communauté (camp, survivants, provisions, sauvegarde) | ⬜ |
| 5 | Polish | ⬜ |

## Journal des décisions

| # | Décision | Statut |
|---|---|---|
| D1 | Moteur : Godot 4 + GDScript typé | ✅ validée par le développeur |
| D2 | Dépôt dédié `last-haven` | ✅ validée — **appliquée provisoirement** : le projet vit dans le dossier `last-haven/` de ce dépôt (la session était limitée à ce dépôt, et ça évite d'écraser le README du profil GitHub). Se déplace tel quel vers un dépôt dédié. |
| D3 | Développement en local sur Windows | ✅ validée |
| D4 | Pas de collision joueur↔joueur en MVP | ✅ validée |
| D5 | Sauvegarde du camp locale en MVP | ✅ validée |
| D6 | Code en anglais, textes en français (traduction Godot) | ✅ validée |
| D7 | Configuration machine du développeur | ✅ (captures du Gestionnaire des tâches) **CPU AMD Ryzen 7 5700X** (8 cœurs / 16 threads, ~4,5 GHz) · **RAM 31,9 Go DDR4 à 2133 MHz** (2 barrettes sur 4 emplacements) · **GPU NVIDIA GeForce RTX (modèle exact tronqué sur les captures), 8 Go de VRAM dédiée**, SSD NVMe, Windows. Conséquence : rendu Forward+ conservé, seuil minimal **60 FPS stables en 1080p** (largement à portée pour une arène greybox ; à relever après mesures). Note : sur les captures le GPU était déjà à ~90 % en 3D avec sa VRAM pleine, donc **fermer les autres applications lourdes avant de mesurer des FPS**. |
| D8 | Recettes et composants de départ (Chiffon, Alcool, Lame en Phase 1) | ✅ validée |
| D9 | **Nouveau** — Runner de tests maison au lieu de GUT (GUT non téléchargeable ni vérifiable dans l'environnement initial, runner sans dépendance) | ✅ appliquée, réévaluable |
| D10 | **Nouveau** — Vérification automatique faite avec Godot **4.4.1** headless (paquet Ubuntu, `tools/setup_godot_linux.sh`) ; ta version installée peut être plus récente | ⚠️ à garder en tête si un comportement diffère |

## Limites connues de l'environnement de développement cloud

- Pas de rendu, pas d'écran, pas de GPU : je ne vois jamais l'image. Tout jugement visuel ou de « feeling » vient de toi.
- Godot officiel non téléchargeable (hôtes bloqués) : utilisation de la 4.4.1 d'Ubuntu en headless uniquement.
- Réseau : seul un test local (même machine) sera possible ; la latence réelle devra être testée chez toi.

## Registre des risques (résumé — détail dans `PLAN_INITIAL.md` §8)

| Risque | Gravité | Atténuation |
|---|---|---|
| Netcode autoritaire d'un TPS (prédiction, lag compensation) | Élevée | Prototype réseau isolé (2.0) avant le contenu ; tests de latence et de client malveillant |
| Volume d'animations | Élevée | Doublures en MVP, logique indépendante des animations, exécution reportée |
| Dérive de périmètre | Élevée | Liste de coupe, une phase à la fois, gates de validation |
| « Le fun » non validable par l'IA | Moyenne | Jalons courts, playtests du développeur, gates de fun |
| Droits sur les assets | Moyenne | `ASSETS_LICENSES.md` obligatoire |
| Différence de version Godot (4.4.1 vérifiée vs ta version) | Moyenne | Version affichée dans l'overlay F3 ; épingler la tienne |
