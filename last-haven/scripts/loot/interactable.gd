class_name Interactable
extends StaticBody3D
## Base class of things the player can use by holding the interact key (crates, later more).
## Subclasses must call super() in _ready().

const GROUP := &"interactables"


func _ready() -> void:
	add_to_group(GROUP)


func can_interact(_player: PlayerController) -> bool:
	return true


## Translation key of the prompt shown near the object.
func get_interaction_prompt() -> String:
	return ""


## Seconds the player must hold the key.
func get_interaction_duration() -> float:
	return 0.5


func interact(_player: PlayerController) -> void:
	pass
