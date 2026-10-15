class_name CameraRig
extends Node3D
## Over-the-shoulder camera pivot.
##
## Detached from the player's rotation ([member Node3D.top_level]) so the body can turn freely
## while the camera only follows its position. Mouse look is handled here; the player reads
## [member yaw] to know where the camera points.
## Click the window to capture the mouse, Esc to release it.

@export var mouse_sensitivity: float = 0.0025
@export_range(-89.0, 0.0) var min_pitch_degrees: float = -65.0
@export_range(0.0, 89.0) var max_pitch_degrees: float = 70.0
## How fast the pivot eases to a new height when crouching/standing.
@export var height_smoothing: float = 12.0

## Rotation around the Y axis, radians. 0 looks toward -Z.
var yaw: float = 0.0
var pitch: float = 0.0
var target_height: float = 1.6

var _current_height: float = 1.6

@onready var _pitch_pivot: Node3D = $PitchPivot
@onready var _target: Node3D = get_parent() as Node3D


func _ready() -> void:
	top_level = true
	_current_height = target_height
	_apply_rotation()
	global_position = _target.global_position + Vector3.UP * _current_height
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_current_height = lerpf(_current_height, target_height, 1.0 - exp(-height_smoothing * delta))
	global_position = _target.global_position + Vector3.UP * _current_height


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		yaw -= motion.relative.x * mouse_sensitivity
		pitch = clampf(
			pitch - motion.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)
		_apply_rotation()
	elif (
		event is InputEventMouseButton
		and (event as InputEventMouseButton).pressed
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _apply_rotation() -> void:
	rotation.y = yaw
	_pitch_pivot.rotation.x = pitch
