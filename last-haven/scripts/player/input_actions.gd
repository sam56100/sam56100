class_name InputActions
extends RefCounted
## Input action names and their default bindings, registered from code.
##
## Keys are bound by PHYSICAL position, so the same keys work on every layout:
## "W" below is the key above "S", i.e. Z on an AZERTY keyboard (ZQSD) and W on QWERTY (WASD).

const MOVE_FORWARD := &"move_forward"
const MOVE_BACK := &"move_back"
const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const SPRINT := &"sprint"
const JUMP := &"jump"
const CROUCH := &"crouch"


static func register() -> void:
	_bind(MOVE_FORWARD, KEY_W)
	_bind(MOVE_BACK, KEY_S)
	_bind(MOVE_LEFT, KEY_A)
	_bind(MOVE_RIGHT, KEY_D)
	_bind(SPRINT, KEY_SHIFT)
	_bind(JUMP, KEY_SPACE)
	_bind(CROUCH, KEY_C)


static func _bind(action: StringName, physical_keycode: Key) -> void:
	# Respect actions already defined (e.g. in project.godot or a future rebinding menu).
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	InputMap.action_add_event(action, event)
