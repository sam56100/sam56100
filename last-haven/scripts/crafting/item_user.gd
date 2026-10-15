class_name ItemUser
extends Node
## Uses crafted items. For now: the heal kit (H), a short interruptible action.

signal item_used(kind: CraftedItem.Kind)

@export var heal_amount: int = 60
@export var use_seconds: float = 1.2

var _player: PlayerController
var _action := TimedAction.new()


func setup(player: PlayerController) -> void:
	_player = player
	player.health.damaged.connect(_on_damaged)


func tick(frame: InputFrame, delta: float) -> void:
	if _action.active:
		if _player.is_dead() or ActionInterrupts.breaks(frame):
			cancel()
		elif _action.tick(delta):
			_finish()
		return
	if frame.use_heal_pressed:
		begin_heal()


## Starts using a heal kit. Returns false if there is nothing to heal or no kit.
func begin_heal() -> bool:
	if _action.active or _player.is_dead():
		return false
	if _player.items.count(CraftedItem.Kind.HEAL_KIT) <= 0:
		return false
	if _player.health.current_health >= _player.health.max_health:
		return false
	if not _player.try_begin_action(self):
		return false
	_action.start(use_seconds)
	return true


func cancel() -> void:
	if not _action.active:
		return
	_action.cancel()
	_player.end_action(self)


func is_using() -> bool:
	return _action.active


func progress() -> float:
	return _action.progress()


func _finish() -> void:
	_player.end_action(self)
	if not _player.items.remove(CraftedItem.Kind.HEAL_KIT):
		return
	_player.health.heal(heal_amount)
	item_used.emit(CraftedItem.Kind.HEAL_KIT)


func _on_damaged(_amount: int) -> void:
	cancel()
