# LAST HAVEN — Plan initial (Mission 1 : analyse, avant tout code)

> Statut : **proposition, en attente de validation.** Aucun code de jeu n'a été écrit.
> Ce document répond aux 8 points de la première mission. Les décisions à valider sont regroupées en section 9.

---

## 0. Limites de l'environnement dans lequel ce plan a été écrit

À lire en premier, parce que ça conditionne la façon de travailler.

| Constat (vérifié le jour de l'écriture) | Conséquence |
|---|---|
| Session cloud Linux, dépôt vide (aucun commit), pas de GPU, pas d'écran | Je ne peux **ni lancer, ni voir, ni jouer** le jeu ici |
| Godot 4 absent. Les hôtes de téléchargement (`downloads.godotengine.org`, releases GitHub) sont **bloqués** par la politique réseau (403 du proxy). `apt` ne propose que Godot **3.5**, inutilisable pour un projet Godot 4 | Impossible d'exécuter un script Godot, un test ou un serveur ici, en l'état |
| `docs.godotengine.org` et `godotengine.org` sont injoignables | Les détails d'API Godot ci-dessous viennent de ma connaissance, **à confirmer sur la doc de la version retenue** avant implémentation |
| `pip` fonctionne : `gdtoolkit` (parseur / linter / formateur GDScript 4) est installable | Je peux faire de la **vérification statique** (syntaxe, style), pas de la vérification d'exécution |

**Ce que ça veut dire concrètement :** la vraie boucle de développement doit tourner **sur ta machine Windows**, avec Claude Code en local, où Godot est installé et où tu peux jouer. Ici, je peux rédiger, planifier et linter, mais « ça marche » ne sera vrai que quand ça a été exécuté chez toi.
Alternative : autoriser ces hôtes dans la politique réseau de l'environnement cloud (voir section 9, décision D3).

Règle de travail qui en découle : chaque fonctionnalité a un statut explicite (voir `SUIVI_PROJET.md`) — **jamais « terminé » sans avoir été exécutée**.

---

## 1. Analyse de faisabilité

**Verdict : faisable par paliers, à condition de rester discipliné sur le périmètre.**

Le jeu décrit en entier (4v4 en ligne, 6 types d'armes, crafting, killstreaks, escouades, méta-jeu de communauté, événements hebdomadaires, plusieurs modes) représente des années-homme dans un studio. Un développeur indépendant assisté par IA peut livrer, de façon réaliste, **un prototype 4v4 jouable entre amis** — c'est ce qu'on vise.

| Bloc | Difficulté | Remarque |
|---|---|---|
| Contrôleur TPS, caméra, tir hitscan, santé | Moyenne | Bien documenté, itératif |
| Loot, crafting à 6 composants, HUD | Faible | Logique simple, data-driven |
| Camp, survivants, provisions, sauvegarde | Faible à moyenne | Surtout de l'UI + données |
| **Netcode autoritaire d'un TPS (prédiction, réconciliation, lag compensation)** | **Élevée** | Le vrai mur technique |
| **Animations (locomotion, visée, couverture, à terre, réanimation, exécution)** | **Élevée (coût de contenu)** | Voir section 8 |
| Couverture (cover system) | Moyenne à élevée | Détection, snap, déplacement le long du mur, réseau |
| Matchmaking, comptes, anti-triche, serveurs publics | Élevée | **Hors MVP** |
| Équilibrage / « le fun » | Inconnue | Ne se valide qu'en jouant |

**Coût financier du MVP : 0 €.** Postes payants éventuels, tous optionnels et plus tard : un petit VPS pour héberger un serveur dédié (quelques €/mois), les frais de publication Steam, des assets sous licence payante.

**Limite propre à ce mode de travail :** je ne vois pas le jeu tourner. Le « feeling » (poids des déplacements, recul, caméra) dépendra de **tes retours de playtest** — d'où des jalons courts et des « gates de fun » entre les phases.

---

## 2. Choix du moteur : Godot 4 vs Unreal Engine 5

| Critère | Godot 4 | Unreal Engine 5 |
|---|---|---|
| Coût | Gratuit, licence MIT, pas de redevance | Gratuit pour démarrer ; redevance au-delà d'un seuil de revenus (conditions à vérifier chez Epic) |
| Installation / poids | Un exécutable (~quelques centaines de Mo), démarrage instantané | Plusieurs dizaines à >100 Go, Visual Studio requis pour le C++ |
| Langage | GDScript (proche de Python), C# possible | C++ ou Blueprints |
| **Adéquation au travail avec une IA** | **Excellente** : scripts et scènes (`.tscn`) en texte, lisibles, diffables, éditables par Claude Code | **Médiocre** : Blueprints et assets en binaire (`.uasset`), compilation C++ lente, éditeur indispensable pour presque tout |
| Itération | Très rapide (F5, rechargement à chaud des scripts) | Plus lourde (compilation, shaders) |
| Rendu | Bon, suffisant pour du réaliste « optimisé » ; moins spectaculaire (pas de Nanite/Lumen) | Référence du marché |
| Netcode TPS | API haut niveau (ENet, RPC, `MultiplayerSpawner/Synchronizer`) mais **pas de prédiction/lag compensation fournie** : à écrire | Character Movement Component avec prédiction fournie, réplication mature, exemple Lyra (TPS) |
| Animations | `AnimationTree`, `BlendSpace2D`, retargeting à l'import : suffisant mais plus manuel | Outillage supérieur (Control Rig, retargeting, motion matching) |
| Serveur dédié | Export headless, même projet | Mature |
| Maintenance par un solo | Simple | Lourde |

**Recommandation : Godot 4 (dernière version stable 4.x), en GDScript typé.**

Argument décisif : l'objectif est « développeur indépendant assisté par IA ». Avec Godot, presque tout le projet est du texte que je peux écrire, relire, linter et versionner. Avec UE5, une grande partie du travail passe par l'éditeur graphique, que je ne peux pas piloter.
Contrepartie assumée : **le netcode de prédiction et de lag compensation sera à écrire par nous**, là où UE5 en fournit une base. C'est le risque n°1 (section 8), traité avec un prototype dédié avant d'investir dans le contenu.

Version : une recherche web pointe vers la série **4.7.x** comme actuelle, mais je n'ai pas pu le confirmer depuis la source officielle. **À toi de télécharger la dernière stable sur godotengine.org ; on épinglera la version exacte dans le dépôt** (une montée de version en cours de projet = risque de casse).
Rendu : Forward+ par défaut, repli Compatibility si la machine est limitée (config à préciser, D7).
C# écarté : build .NET et export plus lourds, GDScript suffit et itère plus vite. GDExtension (C++) seulement si le profilage l'exige, bien plus tard.

---

## 3. Structure de dossiers proposée

Principes : (1) **séparer simulation et présentation** (la logique de jeu ne dépend ni des animations ni de l'UI) ; (2) **séparer ce qui tourne sur le serveur, le client, ou les deux** ; (3) **données dans des `Resource` `.tres`** (armes, composants, recettes, bâtiments) pour équilibrer sans toucher au code ; (4) logique pure testable sans lancer le jeu.

```
last-haven/
├── project.godot
├── CLAUDE.md                  # conventions + commandes pour Claude Code
├── README.md                  # comment lancer / tester
├── .gitignore  .gitattributes # .godot/, export/ ignorés ; LFS pour binaires
├── docs/
│   ├── PLAN_INITIAL.md        # ce document
│   ├── SUIVI_PROJET.md        # avancement + fonctionnalités validées
│   ├── ARCHITECTURE.md        # (créé en Phase 1)
│   └── ASSETS_LICENSES.md     # registre : source + licence de CHAQUE asset
├── data/                      # Resources .tres : weapons/ components/ recipes/ ...
├── scenes/
│   ├── maps/  characters/  weapons/  props/  ui/
├── scripts/
│   ├── core/                  # autoloads minimaux (EventBus, Game, Settings)
│   ├── shared/                # logique identique client+serveur (dégâts, recettes, loot)
│   ├── player/                # contrôleur, caméra, états
│   ├── combat/                # armes, hitboxes, santé
│   ├── loot/  crafting/
│   ├── ui/
│   ├── net/                   # ← Phase 2 seulement
│   ├── modes/                 # ← Phase 3 (supply_war, tickets, objectifs)
│   └── community/             # ← Phase 4 (camp, survivants, sauvegarde)
├── assets/                    # modèles, textures, audio, anims (+ licences)
├── addons/                    # GUT (tests), éventuels addons tiers
├── tests/                     # tests unitaires headless
└── tools/                     # scripts lint/test/export
```

On ne crée **que** les dossiers nécessaires à la phase en cours (pas de squelette vide pour les phases 2–4).

**Dépôt :** le dépôt actuel `sam56100/sam56100` semble être ton dépôt de profil GitHub (vide). Recommandation : un **dépôt dédié `last-haven`** (voir D2). Ces documents s'y déplaceront tels quels.

---

## 4. Dépendances

**Indispensables (gratuites)**

| Outil | Rôle |
|---|---|
| Godot 4.x stable, édition standard (pas .NET), Windows 64 bits | Moteur. Prendre l'exécutable **et** la variante `_console.exe` (sortie texte pour la CLI) |
| Godot **export templates** (même version) | Pour produire un `.exe` jouable |
| Git for Windows + dépôt GitHub | Versionnement ; recommandé aussi pour l'outil Bash de Claude Code |
| Claude Code (Windows) | Développement assisté |
| Python 3 + `gdtoolkit` (`pip install gdtoolkit`) | `gdlint`, `gdformat`, `gdparse` : vérification statique du GDScript 4 |
| **GUT** (Godot Unit Test), addon MIT | Tests unitaires lancés en headless |

**Utiles / plus tard**

| Outil | Quand |
|---|---|
| Git LFS | Dès qu'on versionne des modèles/textures/audio |
| Blender (gratuit) | Si besoin de retoucher/exporter des modèles en glTF |
| Tailscale / ZeroTier (offres gratuites à vérifier) | Tests réseau avec des amis sans ouvrir de ports (Phase 2) |
| VPS Linux | Serveur dédié headless (optionnel, payant, Phase 2+) |
| GodotSteam (MIT) | Seulement si publication Steam |

**Assets gratuits (à vérifier un par un, voir `ASSETS_LICENSES.md`)** : Kenney et Quaternius (souvent CC0), Poly Haven / ambientCG (CC0) pour textures et HDRI, packs d'animations de personnage CC0. Les animations Mixamo ont leurs propres conditions d'utilisation à relire avant tout usage. **Aucun asset n'entre dans le dépôt sans ligne dans le registre de licences.**

**Évités volontairement :** serveurs MCP Godot communautaires non audités (risque de chaîne d'approvisionnement ; Claude Code pilote déjà Godot via sa ligne de commande), addons réseau tiers tant que l'API native suffit.

---

## 5. Définition précise du MVP

Deux niveaux, pour éviter l'ambiguïté du mot « MVP » :

### MVP-A — « Vertical slice solo » (= Phase 1)
**Contenu :** 1 petite carte greybox, 1 personnage, caméra TPS épaule, visée, 1 arme hitscan (cadence, recul, dispersion, chargeur, rechargement), cibles d'entraînement avec zones (tête / torse / membres), 1 caisse de loot, 3 composants, craft d'un kit de soin, HUD minimal.
**Critères d'acceptation (tous testables) :**
- Le projet se lance depuis l'éditeur et en `.exe`, **0 erreur et 0 avertissement** dans la console au démarrage.
- Déplacement, sprint, accroupi ; la caméra ne traverse pas les murs.
- Tirer sur une cible applique les bons dégâts selon la zone (**tests unitaires verts**).
- Ouvrir une caisse prend ≤ 1 s et donne des composants ; fabriquer un soin prend ≈ 1,5–2 s, est interruptible, et rend de la santé.
- Le HUD affiche santé, munitions, composants.
- Au moins 60 images/s stables en 1080p sur ta machine (GPU dédié 8 Go de VRAM, environ 32 Go de RAM : le seuil sera relevé si les mesures le permettent).

### MVP-B — « Supply War jouable » (= fin de Phase 3, version minimale)
**Contenu :** 1 carte, 1 mode (Supply War), 4v4 sur serveur dédié, 3 armes à feu + 1 mêlée, mise à terre + réanimation, tickets de réapparition, 1 type d'objectif (zone à tenir), crafting de 3 objets (soin, cocktail incendiaire, fumigène), **1** récompense de série (détection à 3 éliminations), score et écran de résultats.
**Critères d'acceptation :**
- 4 clients (humains et/ou clients de test scriptés) jouent **10 minutes sans crash** ; fin de match par tickets ; écran de résultats.
- Jouable avec une **latence simulée de 100 ms** (outil de latence artificielle intégré).
- Le serveur **rejette** les entrées invalides (tests dédiés — voir 8.1). *Autoritaire ne veut pas dire « sécurisé » : ça se démontre par des tests, pas par une affirmation.*

### Hors MVP (liste de coupe explicite)
Camp / survivants / provisions (Phase 4) · escouades et invitations · matchmaking · comptes · personnalisation d'armes · bombe artisanale et amélioration de mêlée · exécutions (animations appariées) · franchissement d'obstacles · killstreaks au-delà de la première · événements communautaires · chat vocal · anti-triche · manette (clavier/souris d'abord) · modes supplémentaires · IA.

---

## 6. Étapes de développement

Règle : **une phase à la fois, un jalon à la fois, validation avant de passer au suivant.**
Les durées sont des **ordres de grandeur très approximatifs** (temps partiel, à recaler après la Phase 1).

### Phase 0 — Mise en place (quelques heures)
Installer Godot, Git, Claude Code ; créer le dépôt ; `CLAUDE.md` ; projet vide qui se charge en headless ; `gdtoolkit` et GUT câblés ; épingler la version de Godot.

### Phase 1 — Vertical slice solo (≈ 2–4 semaines)

| Jalon | Contenu | Vérification |
|---|---|---|
| 1.0 | Squelette de projet, `CLAUDE.md`, commandes lint/test, scène de démarrage | Chargement headless sans erreur ; lint OK |
| 1.1 | Carte greybox + capsule : marche, sprint, accroupi, saut simple | Playtest : le déplacement est agréable |
| 1.2 | Caméra TPS épaule (SpringArm, inversion d'épaule, zoom de visée) | Playtest : pas de clipping, visée lisible |
| 1.3 | Arme hitscan : cadence, recul, dispersion, chargeur, rechargement (**minuteurs, pas dépendants des animations**) | Tests unitaires + playtest |
| 1.4 | Composant santé/dégâts, cibles avec zones | Tests unitaires (calcul de dégâts) |
| 1.5 | Caisse de loot + 3 composants | Tests unitaires (table de loot) + playtest |
| 1.6 | Crafting compact/radial + soin | Tests unitaires (recettes) + playtest |
| 1.7 | HUD (santé, munitions, composants, réticule, hit marker, invite d'interaction) | Playtest |
| 1.8 | Passe de correctifs, build `.exe`, check-list de playtest | **Gate de fun** : ta décision de continuer ou de corriger |

### Phase 2 — Premier multijoueur (≈ 1,5–3 mois, la plus risquée)
2.0 **Prototype d'architecture réseau isolé** (voir 8.1) avant d'y brancher le gameplay · 2.1 deux joueurs, déplacement autoritaire avec prédiction · 2.2 tir autoritaire + feedback · 2.3 mort/réapparition, score · 2.4 latence/perte simulées + mesures · 2.5 passage à 4 · 2.6 tests d'entrées invalides. **Gate : jouable à 100 ms simulés.**

### Phase 3 — Gameplay PvP (≈ 2–4 mois)
Couverture · mise à terre/réanimation · tickets · objectif de zone · armes supplémentaires · crafting complet · 1 récompense de série. Gate de fun après chaque système.

### Phase 4 — Communauté (≈ 1–2 mois)
Camp, 10 survivants (nom, santé, moral, statut), provisions (ressource **distincte** des composants de match), bâtiments, sauvegarde, résultats de match → camp. Aucune pénalité hors-ligne. Voir D5 pour la question de la confiance dans la sauvegarde.

### Phase 5 — Polish (ouverte)
Animations, sons, effets, sensation des armes, interfaces, performances, équilibrage.

---

## 7. Configurer Claude Code avec Godot sur Windows

**Choix recommandé : Windows natif, pas WSL.** Godot est un exécutable Windows, et on veut lancer l'éditeur et le jeu avec la carte graphique. Contrepartie (documentée par Anthropic) : sur Windows natif, le *sandboxing* de Claude Code n'est pas disponible → on garde les confirmations de permission actives et on ne passe pas en mode « tout autoriser ».

1. **Git for Windows** — https://git-scm.com/downloads/win (recommandé pour l'outil Bash de Claude Code ; sans lui, Claude Code utilise PowerShell).
2. **Claude Code** — dans PowerShell : `irm https://claude.ai/install.ps1 | iex` (ou `winget install Anthropic.ClaudeCode`). Puis, dans un **nouveau** terminal : `claude --version` et `claude doctor`. Nécessite un abonnement ou compte Console compatible Claude Code.
3. **Godot** — télécharger la dernière stable sur godotengine.org, dézipper dans un dossier fixe (ex. `C:\Tools\Godot\`), ajouter ce dossier au `PATH`, et créer un alias/copie `godot.exe` pointant vers la variante **`_console.exe`** pour obtenir les logs dans le terminal. Installer aussi les *export templates* (menu *Éditeur → Gérer les modèles d'exportation*).
4. **Python + gdtoolkit** — `pip install gdtoolkit` (fournit `gdlint`, `gdformat`).
5. **Dépôt** — cloner le dépôt `last-haven`, ouvrir un terminal **dans le dossier du projet**, lancer `claude`.
6. **`CLAUDE.md`** à la racine (je le rédigerai en Phase 0) : GDScript 4 uniquement (pas de syntaxe Godot 3), typage statique, conventions de nommage, règles d'architecture (simulation ≠ présentation, serveur autoritaire), et surtout **les commandes de vérification** :
   - chargement headless : `godot --headless --path . --quit` (affiche les erreurs de parsing/chargement) ;
   - style : `gdlint .` et `gdformat --check .` ;
   - tests : `godot --headless -s addons/gut/gut_cmdln.gd …` *(options exactes à confirmer dans la doc de GUT)*.
7. **Autorisations** — fichier `.claude/settings.json` du projet avec une liste blanche limitée à ces commandes (godot, gdlint, gdformat, git en lecture), pour réduire les confirmations sans ouvrir en grand.
8. **Boucle de travail** : Claude écrit/modifie les scripts → il lance lint + chargement headless + tests → **tu ouvres Godot (F5), tu joues et tu me rapportes ce que tu ressens** (logs, vidéo courte, ou description). Dans Godot, activer *Éditeur → Paramètres → Éditeur de texte → Comportement → rechargement automatique des scripts modifiés en externe* (nom exact à vérifier dans ta version).
9. **Pratique importante :** pour les scènes complexes, privilégier des **scènes minimales + scripts qui construisent le reste**, plutôt que de faire écrire à la main de gros `.tscn` (risque de scène corrompue). Chaque scène est validée par un chargement headless.

---

## 8. Principales difficultés techniques

### 8.1 PvP réseau (risque n°1)

**Architecture proposée (à valider par prototype en 2.0) :**
- **Serveur dédié headless** = le même projet Godot lancé en mode serveur ; un mode « listen-server » pour les tests rapides utilise le même chemin de code. Transport : ENet via l'API multijoueur de Godot (à confirmer dans la doc de la version retenue).
- **Autoritatif côté serveur** : déplacements, tirs, dégâts, santé, inventaire de composants, crafting, tickets, score, résultats de match. Le client n'envoie que des **intentions** (entrées, « je tire dans cette direction à ce tick »), jamais des résultats.
- **Joueur local : prédiction + réconciliation** (le client simule tout de suite, le serveur corrige). **Joueurs distants : interpolation** (~100 ms de tampon).
- **Tir : lag compensation bornée** — le serveur garde un historique court des positions et « rembobine » (borne ≈ 200 ms) pour valider les touches. Les hitboxes serveur sont des **capsules/boîtes simples (tête, torse, jambes)**, *pas* les os animés : sinon le rembobinage devient lourd et non déterministe.
- **Tick** : physique 60 Hz, instantanés serveur 20–30 Hz. La bande passante pour 8 joueurs est négligeable ; la difficulté est la justesse, pas le débit.
- **État critique en RPC fiable** (santé, état à terre, score, tickets, composants) ; entrées et positions en non fiable.
- **Simplification proposée (D4) :** les joueurs **ne se bloquent pas physiquement entre eux** en MVP. Ça rend la prédiction/réconciliation nettement plus simple, et c'est courant dans les shooters.
- **Les animations ne dictent jamais la logique** : durées de rechargement, de craft, de réanimation = minuteurs côté serveur. Les animations sont cosmétiques et pilotées par l'état répliqué. Le serveur headless n'anime rien.

**Ce qui est à vérifier dès 2.0 :** que `CharacterBody3D` + rejeu d'entrées donne une réconciliation stable avec la physique de Godot (non déterministe entre machines) ; sinon, simplifier le modèle de mouvement du joueur (cinématique contrôlée plutôt que physique libre).

**Tests réseau prévus** (rien n'est « sécurisé » tant que ça n'a pas passé ceci) :
1. Couche de **latence / gigue / perte artificielles** intégrée (portable, sans outil externe) : 50 / 100 / 200 ms.
2. **Clients de test scriptés** (headless) pour lancer des matchs sans humains.
3. **Client « malveillant » de test** : RPC hors cadence, munitions inexistantes, tir depuis une position impossible, dégâts forgés, téléportation, crafting sans composants → le serveur doit tous les rejeter.
4. Un document `MODELE_DE_MENACE.md` en Phase 2.

**Limites assumées dès maintenant :** serveur autoritaire ≠ anti-triche. Aimbot et wallhack ne sont pas traités (le client reçoit les positions adverses). Pour des playtests entre amis, c'est acceptable ; pour du public, il faudrait y revenir.

**Accès réseau pour les amis :** NAT et pare-feu Windows compliquent l'hébergement à domicile → VPN privé gratuit (Tailscale/ZeroTier) pour les tests, VPS si on veut un serveur permanent. Pas de matchmaking en MVP : connexion par adresse ou code.

### 8.2 Animations (risque n°2, surtout en volume de contenu)

Un TPS demande beaucoup d'animations : locomotion 8 directions debout et accroupi, visée avec décalage selon l'inclinaison, tir, rechargement, réactions aux coups, mise à terre, ramper, réanimation, exécution, couverture (entrer, longer, dépasser).
- **Stratégie :** un seul squelette humanoïde ; `AnimationTree` avec `BlendSpace2D` pour la locomotion et un calque haut du corps filtré par os (visée/tir/rechargement) ; retargeting à l'import quand la source n'a pas le même squelette.
- **MVP avec doublures** : mise à terre = chute + ramper en réutilisant des clips ; réanimation = clip générique ; **exécution reportée en Phase 5** (nécessite des animations appariées) ; franchissement d'obstacles coupé.
- **Remplaçable plus tard** : comme la logique ne dépend pas des animations, on pourra les remplacer sans toucher au gameplay.
- Risque légal/qualité : packs gratuits souvent hétérogènes (squelettes, échelles, styles) → registre de licences et un seul pack de base.

### 8.3 Autres difficultés

| Sujet | Risque | Réponse |
|---|---|---|
| **Caméra épaule + tir** | Le réticule (caméra) ne coïncide pas avec le canon ; tirer à travers un mur quand la caméra déborde | Raycast depuis la caméra, puis vérification de ligne de vue depuis le canon ; validé aussi par le serveur |
| **Couverture** | Détection, accroche, déplacement le long du mur, dépassement, état répliqué | Système contextuel simplifié sur colliders étiquetés « couverture », en plusieurs incréments (Phase 3) |
| **Équilibrage du TTK** | Trop létal = frustrant ; trop lent = mou | Armes en `Resource` ; cible initiale de TTK à fixer en 1.3 et à ajuster en playtest |
| **Persistance & confiance** | Une sauvegarde locale est falsifiable | MVP entre amis : sauvegarde locale assumée ; si le jeu devient public, déplacer provisions/progression côté serveur |
| **Code généré par IA** | Mélange de syntaxe Godot 3/4, API inventée, scènes corrompues | Godot 4 épinglé, GDScript typé, lint, chargement headless, tests, jalons courts, revue |
| **Dérive de périmètre** | Le risque le plus probable | Liste de coupe (section 5), une phase à la fois, gates de validation |
| **Assets & droits** | Licences incompatibles | Registre `ASSETS_LICENSES.md`, rien sans ligne |
| **Performances** | Végétation + brouillard + 8 joueurs | Budget fixé après connaissance de ta config ; greybox d'abord |

---

## 9. Décisions à valider (mes recommandations en premier)

| # | Question | Recommandation |
|---|---|---|
| **D1** | Moteur | Godot 4 (stable la plus récente), GDScript typé |
| **D2** | Dépôt | Créer un dépôt dédié `last-haven` (le dépôt actuel semble être ton dépôt de profil) |
| **D3** | Où développer | Claude Code **en local sur Windows** (boucle complète). Ici (cloud) : planification/docs uniquement, sauf si tu autorises le téléchargement de Godot dans l'environnement |
| **D4** | Collision joueur↔joueur en MVP | Désactivée (simplifie la prédiction réseau) |
| **D5** | Sauvegarde du camp | Locale pour le MVP (playtests entre amis) ; côté serveur seulement si ouverture au public |
| **D6** | Langues | Code, commentaires et identifiants en anglais ; documents et textes du jeu en français, via le système de traduction de Godot dès le début |
| **D7** | Ta machine | ✅ Reçu : GPU dédié 8 Go de VRAM, ≈ 32 Go de RAM, CPU inconnu. Forward+ conservé, seuil de 60 FPS en 1080p. |
| **D8** | Recettes et composants de départ | Voir ci-dessous |

### D8 — Proposition de recettes (2 composants chacune, craft rapide)

| Objet | Recette | Phase |
|---|---|---|
| Kit de soin | Chiffon + Alcool | 1 |
| Cocktail incendiaire | Alcool + Sucre | 3 |
| Bombe fumigène | Sucre + Explosif | 3 |
| Bombe artisanale | Explosif + Lame | 5 (hors MVP-B) |
| Amélioration de mêlée | Lame + Adhésif | 5 (hors MVP-B) |

Les 6 composants sont tous utilisés. En Phase 1, les 3 composants sont **Chiffon, Alcool, Lame** ; la Lame n'a pas encore de recette : elle sert à valider le loot et l'interface avec plusieurs types. Dis-moi si tu préfères autre chose.

---

*Prochaine étape après ta validation : Phase 0 (mise en place), puis jalon 1.0.*
