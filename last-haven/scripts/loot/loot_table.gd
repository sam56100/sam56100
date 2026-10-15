class_name LootTable
extends Resource
## Weighted random contents of a crate. Edit the .tres files in data/loot/ to rebalance.

## Component type (a [enum CraftComponent.Type] value) -> relative weight.
@export var weights: Dictionary = {}
## Number of random picks per crate, inclusive.
@export var picks_min: int = 2
@export var picks_max: int = 4


## Rolls the contents of one crate: a Dictionary of component type -> amount.
func roll(rng: RandomNumberGenerator) -> Dictionary:
	var result: Dictionary = {}
	var total := 0.0
	for type: int in weights:
		total += float(weights[type])
	if total <= 0.0:
		return result
	var picks := rng.randi_range(picks_min, maxi(picks_min, picks_max))
	for i in picks:
		var chosen := _pick(rng, total)
		result[chosen] = int(result.get(chosen, 0)) + 1
	return result


func _pick(rng: RandomNumberGenerator, total: float) -> int:
	var remaining := rng.randf() * total
	var last := 0
	for type: int in weights:
		last = type
		remaining -= float(weights[type])
		if remaining <= 0.0:
			return type
	return last
