class_name PlayerController
extends CharacterBody3D
## Third-person player body.
##
## The simulation ([method simulate]) only consumes an [InputFrame], never the keyboard directly,
## so the exact same code can later run on the server (authoritative) and on the client
## (prediction). See docs/ARCHITECTURE.md.

signal stance_changed(new_stance: Stance)

enum Stance { STANDING, CROUCHING }

const _MOVE_DEADZONE := 0.1
const _STAND_PROBE_MARGIN := 0.05
const _CAMERA_HEIGHT_RATIO := 0.88

@export var config: MovementConfig

## When set, used instead of the local keyboard (tests, future network input).
var input_override: InputFrame = null
var stance: Stance = Stance.STANDING

var _stand_probe: CapsuleShape3D

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _body_mesh: Node3D = $Body
@onready var _camera_rig: CameraRig = $CameraRig


func _ready() -> void:
	if config == null:
		config = MovementConfig.new()
	_stand_probe = CapsuleShape3D.new()
	_stand_probe.radius = config.radius
	_stand_probe.height = config.stand_height - 2.0 * _STAND_PROBE_MARGIN
	_apply_stance_shape()


func _physics_process(delta: float) -> void:
	var frame := input_override if input_override != null else _read_local_input()
	simulate(frame, delta)


## Advances the player by one physics tick from the given intent.
func simulate(frame: InputFrame, delta: float) -> void:
	var stance_changed_this_tick := _update_stance(frame)
	var wish_direction := _wish_direction(frame)
	_accelerate_horizontally(wish_direction * _target_speed(frame), delta)
	_apply_vertical(frame, delta, not stance_changed_this_tick)
	_face(wish_direction, delta)
	move_and_slide()


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _read_local_input() -> InputFrame:
	var frame := InputFrame.new()
	frame.move = Input.get_vector(
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.MOVE_BACK,
		InputActions.MOVE_FORWARD
	)
	frame.aim_yaw = _camera_rig.yaw
	frame.sprint = Input.is_action_pressed(InputActions.SPRINT)
	frame.jump_pressed = Input.is_action_just_pressed(InputActions.JUMP)
	frame.crouch_toggle_pressed = Input.is_action_just_pressed(InputActions.CROUCH)
	return frame


func _wants_sprint(frame: InputFrame) -> bool:
	return frame.sprint and frame.move.y > _MOVE_DEADZONE


## Returns true if the stance changed this tick.
func _update_stance(frame: InputFrame) -> bool:
	var before := stance
	if frame.crouch_toggle_pressed:
		if stance == Stance.CROUCHING:
			_try_stand()
		else:
			_set_stance(Stance.CROUCHING)
	elif stance == Stance.CROUCHING and (_wants_sprint(frame) or frame.jump_pressed):
		# Sprinting or jumping from a crouch first stands up (if there is room).
		_try_stand()
	return stance != before


func _target_speed(frame: InputFrame) -> float:
	if stance == Stance.CROUCHING:
		return config.crouch_speed
	if _wants_sprint(frame):
		return config.sprint_speed
	return config.walk_speed


## Camera-relative movement direction on the ground plane, length <= 1.
func _wish_direction(frame: InputFrame) -> Vector3:
	var yaw_basis := Basis(Vector3.UP, frame.aim_yaw)
	var direction := yaw_basis * Vector3(frame.move.x, 0.0, -frame.move.y)
	return direction.limit_length(1.0)


func _accelerate_horizontally(target_velocity: Vector3, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var rate := config.air_acceleration
	if is_on_floor():
		if target_velocity.length_squared() > 0.0:
			rate = config.ground_acceleration
		else:
			rate = config.ground_deceleration
	horizontal = horizontal.move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _apply_vertical(frame: InputFrame, delta: float, allow_jump: bool) -> void:
	if is_on_floor():
		velocity.y = 0.0
		if allow_jump and stance == Stance.STANDING and frame.jump_pressed:
			velocity.y = config.jump_velocity
	else:
		velocity.y = maxf(velocity.y - config.gravity * delta, -config.max_fall_speed)


func _face(wish_direction: Vector3, delta: float) -> void:
	if wish_direction.length_squared() < _MOVE_DEADZONE * _MOVE_DEADZONE:
		return
	var target_yaw := atan2(-wish_direction.x, -wish_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-config.turn_rate * delta))


func _set_stance(new_stance: Stance) -> void:
	if new_stance == stance:
		return
	stance = new_stance
	_apply_stance_shape()
	stance_changed.emit(stance)


func _try_stand() -> bool:
	if not _can_stand():
		return false
	_set_stance(Stance.STANDING)
	return true


## True if a standing capsule fits at the current position (nothing low overhead).
func _can_stand() -> bool:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _stand_probe
	params.transform = Transform3D(
		Basis.IDENTITY, global_position + Vector3.UP * config.stand_height * 0.5
	)
	params.exclude = [get_rid()]
	params.collision_mask = collision_mask
	var hits := get_world_3d().direct_space_state.intersect_shape(params, 1)
	return hits.is_empty()


func _apply_stance_shape() -> void:
	var height := config.stand_height if stance == Stance.STANDING else config.crouch_height
	var capsule := _collision_shape.shape as CapsuleShape3D
	capsule.radius = config.radius
	capsule.height = height
	_collision_shape.position.y = height * 0.5
	_body_mesh.scale.y = height / config.stand_height
	_body_mesh.position.y = height * 0.5
	_camera_rig.target_height = height * _CAMERA_HEIGHT_RATIO
