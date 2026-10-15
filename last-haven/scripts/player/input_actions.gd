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
const AIM := &"aim"
const FIRE := &"fire"
const RELOAD := &"reload"
const SHOULDER_SWAP := &"shoulder_swap"


static func register() -> void:
	_bind_key(MOVE_FORWARD, KEY_W)
	_bind_key(MOVE_BACK, KEY_S)
	_bind_key(MOVE_LEFT, KEY_A)
	_bind_key(MOVE_RIGHT, KEY_D)
	_bind_key(SPRINT, KEY_SHIFT)
	_bind_key(JUMP, KEY_SPACE)
	_bind_key(CROUCH, KEY_C)
	_bind_key(RELOAD, KEY_R)
	_bind_key(SHOULDER_SWAP, KEY_V)
	_bind_mouse(AIM, MOUSE_BUTTON_RIGHT)
	_bind_mouse(FIRE, MOUSE_BUTTON_LEFT)


static func _bind_key(action: StringName, physical_keycode: Key) -> void:
	# Respect actions already defined (e.g. in project.godot or a future rebinding menu).
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	InputMap.action_add_event(action, event)


static func _bind_mouse(action: StringName, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
