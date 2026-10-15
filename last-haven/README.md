# LAST HAVEN

Prototype de TPS tactique PvP à la troisième personne (Godot 4, GDScript).
Plan complet : [`docs/PLAN_INITIAL.md`](docs/PLAN_INITIAL.md) · État d'avancement : [`docs/SUIVI_PROJET.md`](docs/SUIVI_PROJET.md).

**État actuel : Phase 1 (jeu solo) entièrement écrite, en attente de ton playtest** — une arène de test où l'on se
déplace, vise, tire sur des cibles, ouvre des caisses, fabrique un kit de soin et se soigne. Pas encore de réseau
(Phase 2).

## Récupérer le projet sur ton PC (à faire AVANT d'ouvrir Godot)

Le projet est sur GitHub, Godot ne peut importer que des fichiers présents sur ton ordinateur.

**Sans Git (le plus simple) :**
1. Dans ton navigateur (connecté à GitHub), ouvre <https://github.com/sam56100/sam56100>.
2. Clique sur le menu des branches (écrit `main`) et choisis `claude/confident-euler-xvunds`.
3. Bouton vert **Code** → **Download ZIP**.
4. Dézippe le fichier, par exemple dans `C:\Projets\`. Le fichier à importer dans Godot est
   `...\last-haven\project.godot` (dans le sous-dossier `last-haven`, **pas** à la racine du zip, où il n'y en a pas).

**Avec Git (nécessaire plus tard pour Claude Code sur ton PC) :**
`git clone --branch claude/confident-euler-xvunds https://github.com/sam56100/sam56100.git`

## Lancer le jeu (Windows)

1. Installer **Godot 4** (édition standard, pas .NET) depuis <https://godotengine.org/download> et le dézipper
   dans un dossier fixe, par exemple `C:\Tools\Godot\`.
2. Lancer Godot → **Importer** → choisir le fichier `project.godot` de ce dossier → **Importer et éditer**.
   (La première ouverture peut afficher une demande de conversion de version : accepte-la, sauvegarde ensuite.)
3. Appuyer sur **F5** (ou le bouton ▶) pour lancer la scène principale.

Le projet a été écrit et vérifié automatiquement avec Godot **4.4.1** ; une version plus récente devrait
fonctionner, mais si quelque chose casse, note la version exacte (elle s'affiche dans l'overlay F3).

## Commandes

| Action | Touche |
|---|---|
| Se déplacer | **Z Q S D** sur AZERTY (W A S D sur QWERTY — les touches sont liées à leur position physique) |
| Regarder | Souris (clic dans la fenêtre pour la capturer, **Échap** pour la libérer) |
| Sprint | **Maj** (en avançant) |
| S'accroupir (bascule) | **C** |
| Viser (zoom, déplacement ralenti) | **Clic droit** maintenu |
| Tirer | **Clic gauche** (maintenu : tir automatique) |
| Ouvrir une caisse | **E** maintenu (≈ 0,8 s) près d'une caisse |
| Menu de fabrication | **Tab** maintenu, puis **1** pour le kit de soin (≈ 1,5 s) |
| Utiliser un kit de soin | **H** (≈ 1,2 s, +60 PV) |
| Recharger | **R** (rechargement automatique quand le chargeur est vide) |
| Changer d'épaule (caméra) | **V** |
| Se blesser (test, version de développement) | **K** (-30 PV) |
| Sauter | **Espace** |
| Overlay de debug (FPS, vitesse, état) | **F3** |

## À tester (Phase 1) et à me rapporter

Joue 10 minutes en suivant cette liste, puis dis-moi simplement « OK » ou ce qui ne va pas (avec la capture de l'overlay **F3** et du panneau **Sortie** de Godot s'il y a du texte rouge ou jaune).

1. **Déplacement** : marcher, sprinter (Maj), s'accroupir (C), sauter, démarrer/s'arrêter. Du poids sans lenteur ?
2. **Caméra** : souris fluide ? Clic droit (zoom de visée), **V** (changer d'épaule). Traverse-t-elle les murs ?
3. **Tir** : clic gauche maintenu. Le recul, la dispersion, le réticule qui s'ouvre, le tracé jaune. **R** pour recharger.
4. **Cibles** (6 mannequins) : tête = 36, torse = 18, membres = 14, chiffres flottants, croix blanche à la touche (rouge à la mort). Elles tombent et reviennent après 3 s. Tuer au torse prend-il le bon temps (≈ 0,6 s) ?
5. **Caisses** (6, dont une sur la plateforme verte) : s'approcher, **E** maintenu (≈ 0,8 s). Message « +1 Chiffon … ». La caisse se regarnit après 25 s.
6. **Fabrication** : maintenir **Tab**, appuyer sur **1** (Kit de soin = 1 Chiffon + 1 Alcool, ≈ 1,5 s). Interrompu si tu cours, tires, sautes ou es touché.
7. **Soin** : **K** pour te blesser (-30), puis **H** pour utiliser le kit (≈ 1,2 s, +60 PV).
8. **Mort** : tombe à 0 PV (K plusieurs fois) : « Éliminé », retour au départ après 2 s.
9. **Poutre rouge** (debout bloqué, accroupi on passe) et **rampe verte** jusqu'à la plateforme.
10. **Fluidité** : des saccades ? Quels FPS (overlay F3) ?

## Produire un .exe jouable (jalon 1.8, à faire chez toi)

Un préréglage d'export Windows est fourni (`export_presets.cfg`, **non testé**). Dans Godot : *Projet → Exporter…* ; si Godot demande les modèles d'exportation, clique sur *Gérer les modèles d'exportation → Télécharger et installer*, puis *Exporter le projet* vers `export/LastHaven.exe`. Dis-moi ce qui s'affiche s'il y a une erreur.

## Vérifications automatiques

Nécessite Python 3 et `pip install gdtoolkit`, plus `godot` dans le PATH (ou la variable `GODOT_BIN`).
Sous Windows, utiliser le `Godot_..._console.exe` pour avoir les logs dans le terminal.

```
python tools/check.py
```

Format, lint, chargement de tous les fichiers, tests de physique et lancement de la scène principale en headless.
Un résultat vert veut dire « vérifié automatiquement », **pas** « agréable à jouer ».

## Travailler avec Claude Code

Ouvrir un terminal dans ce dossier, puis `claude`. Les règles de travail sont dans [`CLAUDE.md`](CLAUDE.md).
