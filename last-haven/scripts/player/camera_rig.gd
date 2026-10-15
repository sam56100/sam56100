class_name CameraRig
extends Node3D
## Over-the-shoulder camera pivot.
##
## Detached from the player's rotation ([member Node3D.top_level]) so the body can turn freely
## while the camera only follows its position. Mouse look is handled here; the player reads
## [member yaw] to know where the camera points.
## Click the window to capture the mouse, Esc to release it. V swaps shoulder.
## Aiming (set by the player) zooms in, moves the camera closer and slows the mouse.

@export var mouse_sensitivity: float = 0.0025
@export_range(-89.0, 0.0) var min_pitch_degrees: float = -65.0
@export_range(0.0, 89.0) var max_pitch_degrees: float = 70.0
## How fast the pivot eases to a new height when crouching/standing.
@export var height_smoothing: float = 12.0

@export_group("Over the shoulder")
## Sideways camera offset in meters (hip / aiming).
@export var shoulder_offset: float = 0.55
@export var aim_shoulder_offset: float = 0.7
## Distance behind the player in meters (hip / aiming).
@export var hip_arm_length: float = 3.2
@export var aim_arm_length: float = 1.9
@export var hip_fov: float = 75.0
@export var aim_fov: float = 55.0
## Mouse sensitivity multiplier while aiming.
@export var aim_sensitivity_scale: float = 0.6
## How fast the view eases between hip and aim (higher = snappier).
@export var view_transition_speed: float = 14.0

@export_group("Recoil")
## How fast the view settles back after a recoil kick.
@export var recoil_recovery_speed: float = 9.0
@export var max_recoil_degrees: float = 12.0

## Rotation around the Y axis, radians. 0 looks toward -Z.
var yaw: float = 0.0
var pitch: float = 0.0
var target_height: float = 1.6
## +1 = camera over the right shoulder, -1 = left.
var shoulder_side: int = 1

var _current_height: float = 1.6
var _aiming: bool = false
var _recoil_pitch: float = 0.0
var _recoil_yaw: float = 0.0

@onready var _pitch_pivot: Node3D = $PitchPivot
@onready var _arm: SpringArm3D = $PitchPivot/SpringArm3D
@onready var _camera: Camera3D = $PitchPivot/SpringArm3D/Camera3D
@onready var _target: Node3D = get_parent() as Node3D


func _ready() -> void:
	InputActions.register()
	top_level = true
	_current_height = target_height
	_arm.spring_length = hip_arm_length
	_arm.position.x = shoulder_offset * shoulder_side
	_camera.fov = hip_fov
	_apply_rotation()
	global_position = _target.global_position + Vector3.UP * _current_height
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_current_height = lerpf(_current_height, target_height, 1.0 - exp(-height_smoothing * delta))
	global_position = _target.global_position + Vector3.UP * _current_height


func _process(delta: float) -> void:
	_ease_view(delta)
	_settle_recoil(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event as InputEventMouseMotion)
	elif (
		event is InputEventMouseButton
		and (event as InputEventMouseButton).pressed
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed(InputActions.SHOULDER_SWAP):
		swap_shoulder()


## Zoom in / out. Called by the player every tick from its input.
func set_aiming(aiming: bool) -> void:
	_aiming = aiming


func swap_shoulder() -> void:
	shoulder_side = -shoulder_side


## Kicks the view up/right by the given amount; it settles back on its own.
func add_recoil(pitch_degrees: float, yaw_degrees: float) -> void:
	var limit := deg_to_rad(max_recoil_degrees)
	_recoil_pitch = clampf(_recoil_pitch + deg_to_rad(pitch_degrees), -limit, limit)
	_recoil_yaw = clampf(_recoil_yaw + deg_to_rad(yaw_degrees), -limit, limit)
	_apply_rotation()


func get_camera() -> Camera3D:
	return _camera


## The ray through the crosshair (screen centre), recoil included.
func get_aim_ray() -> AimRay:
	return AimRay.create(_camera.global_position, -_camera.global_transform.basis.z)


func _look(motion: InputEventMouseMotion) -> void:
	var sensitivity := mouse_sensitivity * (aim_sensitivity_scale if _aiming else 1.0)
	yaw -= motion.relative.x * sensitivity
	pitch = clampf(
		pitch - motion.relative.y * sensitivity,
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)
	_apply_rotation()


func _ease_view(delta: float) -> void:
	var weight := 1.0 - exp(-view_transition_speed * delta)
	var arm_length := aim_arm_length if _aiming else hip_arm_length
	var side_offset := (aim_shoulder_offset if _aiming else shoulder_offset) * shoulder_side
	var fov := aim_fov if _aiming else hip_fov
	_arm.spring_length = lerpf(_arm.spring_length, arm_length, weight)
	_arm.position.x = lerpf(_arm.position.x, side_offset, weight)
	_camera.fov = lerpf(_camera.fov, fov, weight)


func _settle_recoil(delta: float) -> void:
	if is_zero_approx(_recoil_pitch) and is_zero_approx(_recoil_yaw):
		return
	var weight := 1.0 - exp(-recoil_recovery_speed * delta)
	_recoil_pitch = lerpf(_recoil_pitch, 0.0, weight)
	_recoil_yaw = lerpf(_recoil_yaw, 0.0, weight)
	if absf(_recoil_pitch) < 0.0001:
		_recoil_pitch = 0.0
	if absf(_recoil_yaw) < 0.0001:
		_recoil_yaw = 0.0
	_apply_rotation()


func _apply_rotation() -> void:
	rotation.y = yaw + _recoil_yaw
	_pitch_pivot.rotation.x = clampf(
		pitch + _recoil_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees)
	)
