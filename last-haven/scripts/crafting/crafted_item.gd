class_name CraftedItem
extends RefCounted
## Items the player can craft during a match. Phase 1 only has the heal kit; the other tactical
## items (incendiary bottle, smoke bomb, pipe bomb, melee upgrade) arrive with phase 3.

enum Kind { HEAL_KIT }

const _KEYS := {Kind.HEAL_KIT: "Heal kit"}


## Translation key (English).
static func key(kind: Kind) -> String:
	return _KEYS[kind] as String


static func display_name(kind: Kind) -> String:
	return str(TranslationServer.translate(key(kind)))
