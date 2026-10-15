# LAST HAVEN — Architecture (état : Phase 1 écrite, jalons 1.0 à 1.7)

Document vivant : il décrit ce qui **existe**, pas ce qui est prévu (le prévu est dans `PLAN_INITIAL.md`).

## Principes

1. **Simulation ≠ présentation.** La logique de jeu ne dépend ni des animations ni de l'UI. Les durées (rechargement, craft, réanimation) seront des minuteurs, pas des longueurs d'animation.
2. **Intention → simulation.** Le joueur ne lit jamais le clavier dans sa logique de mouvement : il consomme un `InputFrame` (données pures). C'est ce qui permettra, en Phase 2, d'envoyer les intentions au serveur et de rejouer des entrées pour la prédiction côté client.
3. **Données dans des `Resource`.** Les valeurs d'équilibrage vivent dans `data/` (ex. `MovementConfig`), modifiables dans l'inspecteur Godot sans toucher au code.
4. **Monde reconstructible sans rendu.** La carte est générée par code (`GreyboxMap`), donc un serveur headless pourra construire exactement le même monde de collision.

## Modules actuels

| Module | Rôle |
|---|---|
| `scripts/core/main.gd` | Point d'entrée : environnement, carte, joueur, overlay |
| `scripts/player/input_actions.gd` | Noms des actions + touches par défaut (position physique) |
| `scripts/player/input_frame.gd` | Une « image » d'intention : déplacement, direction de visée, sprint, saut, accroupi |
| `scripts/player/player_controller.gd` | `CharacterBody3D` : marche / sprint / accroupi / saut, orientation du corps, test de place pour se relever |
| `scripts/player/camera_rig.gd` | Caméra épaule : souris, tangage borné, `SpringArm3D` anti-traversée de murs |
| `scripts/player/movement_config.gd` + `data/player/movement_default.tres` | Vitesses, accélérations, gravité, tailles |
| `scripts/combat/weapon_data.gd` + `data/weapons/assault_rifle.tres` | Caractéristiques d'une arme (dégâts, cadence, chargeur, dispersion, recul) |
| `scripts/combat/weapon_state.gd` | Logique d'arme **pure** (munitions, cadence, rechargement, dispersion), sans nœud ni physique : déterministe et testable |
| `scripts/combat/weapon_controller.gd` | Transforme l'intention en tirs : rayon caméra puis rayon depuis le canon (la balle ne traverse pas ce que la caméra survole) |
| `scripts/combat/health_component.gd`, `damage_zone.gd`, `damage_calculator.gd`, `hit_info.gd` | Points de vie, zones du corps et règle unique de calcul des dégâts |
| `scripts/combat/hit_zone.gd`, `training_dummy.gd`, `damage_number.gd` | Volumes de touche simples (tête / torse / membres, couche « hitboxes »), cible d'entraînement, chiffres flottants |
| `scripts/loot/*` + `data/loot/crate_basic.tres` | Les 6 composants, table de loot pondérée (donnée), inventaire sans poids, action chronométrée, objets interactifs et caisse |
| `scripts/crafting/*` + `data/recipes/heal_kit.tres` | Recettes à 2 composants (donnée), fabrication chronométrée et interruptible, inventaire d'objets, utilisation du kit de soin |
| `scripts/player/player_interactor.gd` | Trouve l'objet le plus proche et gère l'action « maintenir pour utiliser » (une seule action à la fois) |
| `scripts/combat/shot_effects.gd` | Tracé et impact **purement visuels** |
| `scripts/ui/hud.gd`, `scripts/ui/crosshair.gd` | HUD (muet : il lit l'état du joueur) et réticule dynamique |
| `scripts/core/localization.gd` | Textes français (clés anglaises dans le code, `tr()`) |
| `scripts/world/greybox_map.gd` | Arène de test 60×60 m : couvertures basses/hautes, poutre basse, rampe + plateforme, caisses |
| `scripts/ui/debug_overlay.gd` | Overlay F3 (FPS, vitesse, état, position, version de Godot) |
| `tests/` | Runner maison (`run_tests.gd`), `TestCase`, chargement de tout le projet (`smoke_load.gd`), tests de physique |
| `tools/check.py` | Un seul point d'entrée pour toutes les vérifications automatiques |

Couches de collision : 1 = monde, 2 = joueurs.

## Flux d'un joueur local

```
clavier/souris ──► PlayerController._read_local_input() ──► InputFrame
                                                              │
                         (tests / réseau : input_override) ───┤
                                                              ▼
                                          PlayerController.simulate(frame, delta)
                                          stance → vitesse → accélération → gravité/saut
                                          → orientation → move_and_slide()
```

## Choix de test

- **Runner maison plutôt que GUT** : GUT n'était ni téléchargeable ni vérifiable dans l'environnement de développement initial, et le runner (≈ 100 lignes) n'a aucune dépendance. Réévaluable si on a besoin de doublures/paramétrage.
- Les tests de mouvement utilisent la **vraie scène joueur** et la vraie physique de Godot (headless, `--fixed-fps 60`).
- Le lanceur attend une image avant de commencer : au tout premier instant, les nœuds ajoutés à la racine n'ont pas encore reçu `_ready()`, ce qui faisait échouer le premier test d'un processus (corrigé, chaque suite passe aussi seule).
- Un test qui n'exécute aucune vérification est un échec : c'est à quoi ressemble, vu de l'extérieur, une erreur de script au milieu d'un test (le lanceur la comptait « réussie » avant ce garde-fou).
- Un chien de garde (1800 images par test) transforme un test bloqué en échec explicite.
- `check.py` considère comme échec toute ligne `SCRIPT ERROR`, `Parse Error`, `ERROR:` ou `WARNING:` dans la sortie de Godot, même si le code de sortie est 0.

## Limites connues (à traiter plus tard, pas des oublis)

- Le déplacement est mis à jour à 60 Hz et la caméra le suit sans interpolation : sur un écran à haute fréquence, le mouvement peut sembler moins fluide. L'interpolation de physique est prévue au polish.
- Pas de montée de marches ni de franchissement d'obstacles (prévu avec le système de couverture, Phase 3).
- Le personnage est une capsule de substitution avec un « nez » pour voir l'orientation. Aucune animation.
- Aucun son. Aucun réseau.
- Les dégâts, le butin, le crafting et les soins sont calculés **localement** (solo). En Phase 2 ils passent côté serveur ; les entrées passent déjà par `InputFrame`, ce qui prépare ce changement.
- La propriété de la souris (`CameraRig.gameplay_input`) est suivie par le jeu et non relue depuis le moteur (la fenêtre de jeu intégrée à l'éditeur et le mode headless ne la rapportent pas toujours).
