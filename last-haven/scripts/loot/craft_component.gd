class_name CraftComponent
extends RefCounted
## The six crafting components (match-only: they are not kept after a match).
##
## Source names are English keys for tr(); the French names live in Localization.

enum Type { ALCOHOL, RAG, BLADE, ADHESIVE, EXPLOSIVE, SUGAR }

const _KEYS := {
	Type.ALCOHOL: "Alcohol",
	Type.RAG: "Rag",
	Type.BLADE: "Blade",
	Type.ADHESIVE: "Adhesive",
	Type.EXPLOSIVE: "Explosive",
	Type.SUGAR: "Sugar",
}

const _COLORS := {
	Type.ALCOHOL: Color(0.45, 0.78, 0.95),
	Type.RAG: Color(0.85, 0.78, 0.65),
	Type.BLADE: Color(0.66, 0.7, 0.78),
	Type.ADHESIVE: Color(0.92, 0.75, 0.2),
	Type.EXPLOSIVE: Color(0.9, 0.35, 0.25),
	Type.SUGAR: Color(0.96, 0.96, 0.96),
}


static func all() -> Array[Type]:
	var result: Array[Type] = [
		Type.ALCOHOL, Type.RAG, Type.BLADE, Type.ADHESIVE, Type.EXPLOSIVE, Type.SUGAR
	]
	return result


## Translation key (English).
static func key(type: Type) -> String:
	return _KEYS[type] as String


## Name in the current language.
static func display_name(type: Type) -> String:
	return str(TranslationServer.translate(key(type)))


static func color(type: Type) -> Color:
	return _COLORS[type] as Color
