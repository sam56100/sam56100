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
| Installation de Godot sur ta machine Windows | ✅ Godot 4.7.2 installé, projet importé et lancé |
| Installation de Git, Claude Code et `gdtoolkit` sur ta machine Windows | ⏳ à faire plus tard (inutile pour simplement jouer au prototype ; évitera de retélécharger un ZIP à chaque mise à jour) |
| Épingler la version exacte de Godot | ✅ **Godot 4.7.2 stable officielle** (v4.7.2.stable.official, visible dans le gestionnaire de projets et l'overlay F3) |

## Phase 1 — Vertical slice solo

| Jalon | Contenu | Statut | Ce qui est vérifié / ce qui reste |
|---|---|---|---|
| 1.0 | Squelette, outillage, scène de démarrage | 🟧 | Tout charge, le jeu tourne 120 images en headless sans erreur ni avertissement |
| 1.1 | Arène greybox + marche / sprint / accroupi / saut + caméra épaule minimale | 🟧 **lancé, feeling pas encore jugé** | 15 tests de physique verts (vitesses, accroupi, passage sous la poutre, saut, atterrissage, orientation). **Lancé par toi sur Godot 4.7.2** (capture) : arène et personnage affichés, caméra par-dessus l'épaule (personnage décalé à gauche), 144 FPS (probablement plafonné par l'écran 144 Hz), au sol, position différente du point d'apparition donc le déplacement répond. **Pas encore jugé : le « poids » du mouvement, la fluidité, la caméra à l'usage, la poutre, la rampe.** Panneau Sortie non montré : erreurs/avertissements éventuels non confirmés. |
| 1.2 | Caméra TPS complète (inversion d'épaule, zoom de visée, déplacement en visée) | 🟧 **non joué** | Tests verts : zoom/FOV et rapprochement en visée, retour en vue normale, inversion d'épaule, déplacement plafonné et sprint bloqué en visée, corps orienté vers la caméra en visée, sensibilité réduite en visée, limites de tangage, recul qui se résorbe. **À juger en jouant : la sensation du zoom, la vitesse de transition, la sensibilité.** |
| 1.3 | Arme hitscan : cadence, chargeur, rechargement, dispersion, recul, tracé du canon, réticule dynamique, textes en français | 🟧 **non joué** | 34 nouveaux tests verts (logique d'arme pure ; vrais tirs contre un mur avec vérification de la ligne de tir depuis le canon ; cadence ; semi-auto ; dispersion tir hanche / visée ; recul ; rechargement auto et manuel ; HUD ; traduction). Vérifié que chaque test **échoue bien** quand je casse le comportement visé. **À juger en jouant : le recul, la dispersion, la cadence, la durée de rechargement (valeurs de départ à ajuster), le réticule.** Pas encore de son ni de dégâts (jalon 1.4). |
| 1.4 | Santé et dégâts par zone (tête ×2, torse ×1, membres ×0,75), cibles d'entraînement (6 dans l'arène) avec chute et réapparition, chiffres de dégâts, marqueur de touche, mort et réapparition du joueur, barre de vie | 🟧 **non joué** | 27 nouveaux tests (88 au total) : calcul de dégâts, santé (plafonds, mort unique), tirs réels sur tête/torse/jambes, nombre de coups pour tuer (torse 6, tête 3, membres 8), cible morte non touchable puis réapparue, joueur mort immobile, réapparition au point de départ sur la vraie scène principale. **Un vrai bug trouvé et corrigé par les tests** (une cible pouvait se recoucher après sa réapparition). **À juger en jouant : la durée pour tuer (≈ 0,6 s au torse à pleine cadence), la lisibilité des zones et des chiffres.** Le calcul des dégâts se fait encore localement : il passera côté serveur en Phase 2. |
| 1.5 | Caisses de loot (6 dans l'arène, dont 1 sur la plateforme), les 6 composants définis (Alcool, Chiffon, Lame, Adhésif, Explosif, Sucre), 3 d'entre eux dans les caisses en Phase 1, ouverture en maintenant E, barre des composants, invite et message de butin en français | 🟧 **non joué** | 30 nouveaux tests (115→117 au total avec les corrections) : table de loot pondérée et reproductible, inventaire (tout-ou-rien), action chronométrée, vraies ouvertures dans le moteur physique (portée, annulation au relâchement / en s'éloignant / en tirant, une seule action à la fois, caisse vide puis regarnie, caisse la plus proche, joueur mort), HUD. Défauts injectés tous détectés. **À juger en jouant : la quantité de butin (2 à 4 par caisse), la durée d'ouverture, la lisibilité des caisses et du HUD.** Tests de la souris de la caméra qui ne testaient rien en headless : réécrits. |
| 1.6 | Crafting compact (Tab + numéro), recette Chiffon + Alcool → kit de soin (1,5 s, interruptible), utilisation du kit (H, 1,2 s, +60 PV plafonné), menu et compteurs en français | 🟧 **non joué** | 28 nouveaux tests (143 au total) dont le **scénario complet de la Phase 1** : se blesser, ouvrir deux caisses, fabriquer, se soigner. Composants consommés seulement à la fin (une fabrication interrompue ne coûte rien) ; interruptions par sprint / tir / saut / dégâts ; une seule action à la fois ; joueur mort. 4 défauts injectés tous détectés. **À juger en jouant : les durées, le menu compact (une liste, pas encore un cercle : il n'y a qu'une recette), la lisibilité.** |
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
| D10 | **Nouveau** — Vérification automatique faite avec Godot **4.4.1** headless (paquet Ubuntu, `tools/setup_godot_linux.sh`). Ta version est la **4.7.2** : le projet s'y lance (converti automatiquement), mais les tests automatiques n'ont **pas** été exécutés sur la 4.7.2 | ⚠️ écart de version connu ; on garde `config/features` en 4.4 dans le dépôt pour l'instant |

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
