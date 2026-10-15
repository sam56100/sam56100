class_name Localization
extends RefCounted
## In-game text localisation.
##
## Source strings in the code are English keys (used with tr()); this file holds the French
## translations. Translations are built from code (no CSV import step) so they work identically in
## the editor, in exported builds and in headless tests.

const FRENCH: Dictionary = {
	"Assault rifle": "Fusil d'assaut",
	"Reloading": "Rechargement",
	"Empty": "Vide",
	"Eliminated": "Éliminé",
	"Crate": "Caisse",
	"Hold [E] to open": "Maintenir [E] pour ouvrir",
	"Opening": "Ouverture",
	"Alcohol": "Alcool",
	"Rag": "Chiffon",
	"Blade": "Lame",
	"Adhesive": "Adhésif",
	"Explosive": "Explosif",
	"Sugar": "Sucre",
}

static var _installed: bool = false


## Registers the French translation (once) and switches to the given locale.
static func setup(locale: String = "fr") -> void:
	if not _installed:
		var translation := Translation.new()
		translation.locale = "fr"
		for key: String in FRENCH:
			translation.add_message(key, FRENCH[key] as String)
		TranslationServer.add_translation(translation)
		_installed = true
	TranslationServer.set_locale(locale)
