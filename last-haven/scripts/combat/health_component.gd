class_name HealthComponent
extends Node
## Hit points of anything that can be hurt or healed (players, training dummies).

signal changed(current: int, maximum: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@export var max_health: int = 100

var current_health: int = 100


func _ready() -> void:
	current_health = max_health


func is_dead() -> bool:
	return current_health <= 0


func health_ratio() -> float:
	return float(current_health) / float(maxi(max_health, 1))


## Returns the damage actually dealt (never more than the remaining health).
func take_damage(amount: int) -> int:
	if is_dead() or amount <= 0:
		return 0
	var dealt := mini(amount, current_health)
	current_health -= dealt
	damaged.emit(dealt)
	changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()
	return dealt


## Returns the health actually restored (never beyond max_health, nothing for the dead).
func heal(amount: int) -> int:
	if is_dead() or amount <= 0:
		return 0
	var gained := mini(amount, max_health - current_health)
	if gained == 0:
		return 0
	current_health += gained
	healed.emit(gained)
	changed.emit(current_health, max_health)
	return gained


## Back to full health (respawn).
func reset() -> void:
	current_health = max_health
	changed.emit(current_health, max_health)
