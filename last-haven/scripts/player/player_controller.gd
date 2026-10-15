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
## Muzzle / gun height as a fraction of the body height (standing 1.8 m -> 1.3 m).
const _MUZZLE_HEIGHT_RATIO := 0.72
const _MUZZLE_OFFSET := Vector2(0.28, -0.75)
const _DEBUG_DAMAGE := 30

@export var config: MovementConfig

## When set, used instead of the local keyboard (tests, future network input).
var input_override: InputFrame = null
var stance: Stance = Stance.STANDING
var weapon: WeaponController
var health: HealthComponent

var _stand_probe: CapsuleShape3D
var _muzzle: Marker3D
var _gun_mesh: MeshInstance3D

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _body_mesh: Node3D = $Body
@onready var _camera_rig: CameraRig = $CameraRig


func _ready() -> void:
	InputActions.register()
	if config == null:
		config = MovementConfig.new()
	_stand_probe = CapsuleShape3D.new()
	_stand_probe.radius = config.radius
	_stand_probe.height = config.stand_height - 2.0 * _STAND_PROBE_MARGIN
	_create_health()
	_create_weapon()
	_apply_stance_shape()


func _physics_process(delta: float) -> void:
	var frame := input_override if input_override != null else _read_local_input()
	simulate(frame, delta)


## Advances the player by one physics tick from the given intent.
func simulate(input: InputFrame, delta: float) -> void:
	if input.debug_damage_pressed and OS.is_debug_build():
		health.take_damage(_DEBUG_DAMAGE)
	# A dead player ignores all input but keeps obeying gravity and friction.
	var frame := _idle_frame(input.aim_yaw) if health.is_dead() else input
	var stance_changed_this_tick := _update_stance(frame)
	var wish_direction := _wish_direction(frame)
	_accelerate_horizontally(wish_direction * _target_speed(frame), delta)
	_apply_vertical(frame, delta, not stance_changed_this_tick)
	_face(frame, wish_direction, delta)
	_camera_rig.set_aiming(frame.aim_pressed)
	move_and_slide()
	weapon.tick(frame, delta)


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func get_camera() -> Camera3D:
	return _camera_rig.get_camera()


func is_dead() -> bool:
	return health.is_dead()


## Brings the player back at full health and ammo, standing, at the given world transform.
func respawn(at: Transform3D) -> void:
	health.reset()
	global_transform = at
	velocity = Vector3.ZERO
	stance = Stance.STANDING
	weapon.refill()
	_set_dead_pose(false)


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
	# Clicks only count while the mouse is captured, so the click that recaptures it is not a shot.
	var mouse_captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	frame.aim_pressed = mouse_captured and Input.is_action_pressed(InputActions.AIM)
	frame.fire_pressed = mouse_captured and Input.is_action_pressed(InputActions.FIRE)
	frame.reload_pressed = Input.is_action_just_pressed(InputActions.RELOAD)
	frame.debug_damage_pressed = (
		OS.is_debug_build() and Input.is_action_just_pressed(InputActions.DEBUG_DAMAGE)
	)
	return frame


func _idle_frame(aim_yaw: float) -> InputFrame:
	var frame := InputFrame.new()
	frame.aim_yaw = aim_yaw
	return frame


func _wants_sprint(frame: InputFrame) -> bool:
	var shooting := frame.aim_pressed or frame.fire_pressed
	return frame.sprint and frame.move.y > _MOVE_DEADZONE and not shooting


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
	var speed := config.walk_speed
	if stance == Stance.CROUCHING:
		speed = config.crouch_speed
	elif _wants_sprint(frame):
		speed = config.sprint_speed
	if frame.aim_pressed:
		speed = minf(speed, config.aim_speed)
	return speed


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


func _face(frame: InputFrame, wish_direction: Vector3, delta: float) -> void:
	if frame.aim_pressed or frame.fire_pressed:
		# Aiming or shooting: the body squares up to where the camera points (strafing stance).
		rotation.y = lerp_angle(rotation.y, frame.aim_yaw, 1.0 - exp(-config.aim_turn_rate * delta))
		return
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
	var muzzle_height := height * _MUZZLE_HEIGHT_RATIO
	_muzzle.position = Vector3(_MUZZLE_OFFSET.x, muzzle_height, _MUZZLE_OFFSET.y)
	_gun_mesh.position = Vector3(_MUZZLE_OFFSET.x, muzzle_height - 0.05, _MUZZLE_OFFSET.y * 0.55)


func _create_health() -> void:
	health = HealthComponent.new()
	health.name = "Health"
	add_child(health)
	health.died.connect(_on_died)


func _on_died() -> void:
	_set_dead_pose(true)


## Cosmetic: lays the placeholder body down when dead and stands it up again.
func _set_dead_pose(dead: bool) -> void:
	_gun_mesh.visible = not dead
	if dead:
		_body_mesh.rotation.x = -PI / 2.0
		_body_mesh.position.y = config.radius
	else:
		_body_mesh.rotation.x = 0.0
		_apply_stance_shape()


func _on_hit_confirmed(info: HitInfo) -> void:
	DamageNumber.spawn(get_parent(), info)


func _create_weapon() -> void:
	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	add_child(_muzzle)

	var gun_box := BoxMesh.new()
	gun_box.size = Vector3(0.07, 0.12, 0.7)
	var gun_material := StandardMaterial3D.new()
	gun_material.albedo_color = Color(0.12, 0.12, 0.13)
	gun_box.material = gun_material
	_gun_mesh = MeshInstance3D.new()
	_gun_mesh.name = "GunMesh"
	_gun_mesh.mesh = gun_box
	add_child(_gun_mesh)

	weapon = WeaponController.new()
	weapon.name = "Weapon"
	add_child(weapon)
	weapon.setup(self, _muzzle)
	weapon.aim_ray_provider = _camera_rig.get_aim_ray
	weapon.recoil_kick.connect(_camera_rig.add_recoil)
	weapon.shot_fired.connect(_on_shot_fired)
	weapon.hit_confirmed.connect(_on_hit_confirmed)


func _on_shot_fired(result: ShotResult) -> void:
	ShotEffects.spawn(get_parent(), result)
