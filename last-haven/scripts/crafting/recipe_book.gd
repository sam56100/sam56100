class_name RecipeBook
extends RefCounted
## Every recipe the player can craft, in menu order (slot 1, 2, ...).
## Explicit preloads (not a directory scan) so it also works in exported builds.

const _HEAL_KIT := preload("res://data/recipes/heal_kit.tres")


static func all() -> Array[Recipe]:
	var recipes: Array[Recipe] = [_HEAL_KIT]
	return recipes
