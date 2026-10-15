class_name ComponentInventory
extends RefCounted
## How many of each crafting component the player carries. No weight, no slots, no durability.

signal changed

var _counts: Dictionary = {}


func count(type: CraftComponent.Type) -> int:
	return int(_counts.get(type, 0))


func total() -> int:
	var sum := 0
	for amount: int in _counts.values():
		sum += amount
	return sum


func add(type: CraftComponent.Type, amount: int = 1) -> void:
	if amount <= 0:
		return
	_counts[type] = count(type) + amount
	changed.emit()


## Adds a whole loot dictionary (component type -> amount) with a single change notification.
func add_all(items: Dictionary) -> void:
	var any := false
	for type: int in items:
		var amount := int(items[type])
		if amount > 0:
			_counts[type] = int(_counts.get(type, 0)) + amount
			any = true
	if any:
		changed.emit()


func can_afford(cost: Dictionary) -> bool:
	for type: int in cost:
		if int(_counts.get(type, 0)) < int(cost[type]):
			return false
	return true


## Removes the cost if the player can afford all of it; otherwise changes nothing.
func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for type: int in cost:
		_counts[type] = int(_counts.get(type, 0)) - int(cost[type])
	changed.emit()
	return true


func clear() -> void:
	_counts.clear()
	changed.emit()
