class_name Recipe
extends Resource
## A crafting recipe: two components in, one item out. Edit the .tres files in data/recipes/.

## Translation key of the recipe name.
@export var display_name: String = "Heal kit"
@export var component_a: CraftComponent.Type = CraftComponent.Type.RAG
@export var component_b: CraftComponent.Type = CraftComponent.Type.ALCOHOL
@export var result: CraftedItem.Kind = CraftedItem.Kind.HEAL_KIT
## Short on purpose: crafting happens in the middle of a fight.
@export var craft_seconds: float = 1.5


## Components consumed, as component type -> amount.
func cost() -> Dictionary:
	var needed: Dictionary = {}
	needed[component_a] = int(needed.get(component_a, 0)) + 1
	needed[component_b] = int(needed.get(component_b, 0)) + 1
	return needed
