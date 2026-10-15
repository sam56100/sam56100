# LAST HAVEN — instructions for Claude Code

Third-person tactical PvP shooter (Godot 4, GDScript). Read `docs/PLAN_INITIAL.md` (plan) and
`docs/SUIVI_PROJET.md` (current state) before working. The user writes in French; answer in French.

## Non-negotiable working rules
- One phase and one milestone at a time. Do not start the next milestone before the user has
  playtested and validated the current one. Ask before any major change.
- **Never claim a feature is done or working unless it was actually run.** Use the status legend in
  `docs/SUIVI_PROJET.md`: `check.py` green = "vérifié automatiquement", only the user playing it
  = "validé". Say plainly what could not be verified (rendering, feel, real network).
- Real working code, no fake stubs standing in for systems. Free and legally reusable assets
  only, each one recorded in `docs/ASSETS_LICENSES.md`. No paid dependencies, no pay-to-win.
- Never claim the multiplayer is "secure" without tests that show it (see plan §8.1).

## Verification (run before every commit)
```
python tools/check.py            # format + lint + load everything + tests + smoke run
python tools/check.py --fix      # let gdformat rewrite files first
python tools/check.py --no-godot # only format + lint (no Godot needed)
python tools/check.py -k movement
```
- Godot comes from `$GODOT_BIN`, else `godot` on the PATH. In a Linux cloud session without the
  official build: `tools/setup_godot_linux.sh` then `export GODOT_BIN=...` (it is Godot **4.4.1**,
  headless only; the user may run a newer version).
- First run on a fresh clone needs `godot --headless --path . --import` (check.py does it) so the
  `class_name` cache exists.
- A new feature comes with tests in `tests/test_*.gd` (subclass `TestCase`, see
  `tests/test_movement.gd` for physics tests). Prove a new check can fail before trusting it.

## Code rules
- GDScript 4 only (never Godot 3 syntax or API), fully statically typed, tabs for indentation,
  `gdformat`/`gdlint` clean. Code, identifiers and comments in English; docs in French.
- Comments explain *why*, not *what*. Public API gets `##` doc comments.
- Simulation is separate from presentation. Gameplay logic must not depend on animations or UI
  (reload/craft/revive durations are timers, not animation lengths).
- Player intent goes through `InputFrame`; simulation reads only that. This keeps the player
  deterministic for server authority and client prediction later (Phase 2).
- Tunable numbers live in `Resource` files under `data/` (e.g. `MovementConfig`), not as magic
  numbers in logic.
- Prefer small scenes plus scripts that build the rest; avoid hand-writing large `.tscn` files.
  Every scene must instantiate in the headless smoke load.
- Keys are bound by physical position (AZERTY and QWERTY both work), see `InputActions`.
- Physics layers: 1 = world, 2 = players.
- Add no folder or system for a later phase before that phase starts.

## Layout
`scripts/{core,player,world,ui}` code · `scenes/` · `data/` Resources · `tests/` · `tools/` ·
`docs/`. Phase 2 will add `scripts/net`, Phase 3 `scripts/modes`, Phase 4 `scripts/community`.
