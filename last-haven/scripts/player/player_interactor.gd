class_name PlayerInteractor
extends Node
## Finds the nearest usable object around the player and runs the hold-to-use action on it.

const INTERACT_RANGE := 2.2

var _player: PlayerController
var _action := TimedAction.new()
var _target: Interactable = null
var _active_target: Interactable = null


func setup(player: PlayerController) -> void:
	_player = player


func tick(frame: InputFrame, delta: float) -> void:
	_target = _find_target()
	var interrupted := frame.fire_pressed or frame.jump_pressed
	if _target == null or not frame.interact_held or interrupted or _player.is_dead():
		_cancel()
		return
	if _action.active and _target != _active_target:
		_cancel()
	if not _action.active:
		if not _player.try_begin_action(self):
			return
		_active_target = _target
		_action.start(_target.get_interaction_duration())
	if _action.tick(delta):
		var finished := _active_target
		_cancel()
		if is_instance_valid(finished) and finished.can_interact(_player):
			finished.interact(_player)


## True when something is in range and usable.
func has_target() -> bool:
	return _target != null


## Translation key of the prompt for the current target, or "" when there is none.
func get_prompt() -> String:
	return _target.get_interaction_prompt() if _target != null else ""


## 0..1 progress of the running action.
func progress() -> float:
	return _action.progress()


func is_interacting() -> bool:
	return _action.active


func _cancel() -> void:
	if _action.active or _active_target != null:
		_action.cancel()
		_active_target = null
		_player.end_action(self)


func _find_target() -> Interactable:
	var best: Interactable = null
	var best_distance := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var candidate := node as Interactable
		if candidate == null or not candidate.can_interact(_player):
			continue
		var distance := _player.global_position.distance_to(candidate.global_position)
		if distance <= best_distance:
			best = candidate
			best_distance = distance
	return best
