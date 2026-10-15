# LAST HAVEN

Prototype de TPS tactique PvP à la troisième personne (Godot 4, GDScript).
Plan complet : [`docs/PLAN_INITIAL.md`](docs/PLAN_INITIAL.md) · État d'avancement : [`docs/SUIVI_PROJET.md`](docs/SUIVI_PROJET.md).

**État actuel : Phase 1, jalons 1.0 et 1.1** — une arène de test et un personnage qui se déplace.
Pas encore de tir, de loot ni de réseau.

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
| Changer d'épaule (caméra) | **V** |
| Sauter | **Espace** |
| Overlay de debug (FPS, vitesse, état) | **F3** |

## À tester (jalon 1.1) et à me rapporter

- Le déplacement a-t-il du poids sans être lent ? (marche / sprint / accroupi, démarrage et arrêt)
- La caméra par-dessus l'épaule est-elle lisible ? Traverse-t-elle les murs ?
- Passer sous la poutre rouge : debout c'est bloqué, accroupi ça passe.
- Monter la rampe verte jusqu'à la plateforme.
- Y a-t-il des saccades ? (indique ton FPS et ta config)
- Colle-moi le contenu de l'overlay **F3** si quelque chose te semble faux.

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
