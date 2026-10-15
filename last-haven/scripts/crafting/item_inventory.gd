class_name ItemInventory
extends RefCounted
## Crafted items the player carries (heal kits, ...).

signal changed

var _counts: Dictionary = {}


func count(kind: CraftedItem.Kind) -> int:
	return int(_counts.get(kind, 0))


func add(kind: CraftedItem.Kind, amount: int = 1) -> void:
	if amount <= 0:
		return
	_counts[kind] = count(kind) + amount
	changed.emit()


## Removes items if the player has enough; otherwise changes nothing.
func remove(kind: CraftedItem.Kind, amount: int = 1) -> bool:
	if amount <= 0 or count(kind) < amount:
		return false
	_counts[kind] = count(kind) - amount
	changed.emit()
	return true
