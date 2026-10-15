class_name TimedAction
extends RefCounted
## A short hold-to-complete action (opening a crate, crafting, healing). Time only advances
## through [method tick], so it is deterministic and independent of any animation.

var duration: float = 0.0
var elapsed: float = 0.0
var active: bool = false


func start(seconds: float) -> void:
	duration = maxf(seconds, 0.001)
	elapsed = 0.0
	active = true


func cancel() -> void:
	active = false
	elapsed = 0.0


## Advances the action. Returns true on the tick it completes.
func tick(delta: float) -> bool:
	if not active:
		return false
	elapsed += delta
	if elapsed >= duration:
		active = false
		return true
	return false


## 0..1 while running, 0 otherwise.
func progress() -> float:
	if not active:
		return 0.0
	return clampf(elapsed / duration, 0.0, 1.0)
