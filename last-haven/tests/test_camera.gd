extends TestCase
## Over-the-shoulder camera: shoulder swap, aim zoom, recoil kick and pitch limits.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")

var _world: Node3D
var _player: PlayerController
var _rig: CameraRig
var _arm: SpringArm3D
var _camera: Camera3D


func before_each() -> void:
	_world = Node3D.new()
	tree.root.add_child(_world)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = PhysicsLayers.WORLD
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_world.add_child(floor_body)
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_world.add_child(_player)
	_player.input_override = InputFrame.new()
	_rig = _player.get_node("CameraRig") as CameraRig
	_arm = _rig.get_node("PitchPivot/SpringArm3D") as SpringArm3D
	_camera = _rig.get_camera()
	await _frames(30)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


func test_starts_over_the_right_shoulder_at_hip_zoom() -> void:
	assert_almost_eq(_arm.position.x, _rig.shoulder_offset, 0.01)
	assert_almost_eq(_arm.spring_length, _rig.hip_arm_length, 0.05)
	assert_almost_eq(_camera.fov, _rig.hip_fov, 0.1)


func test_swap_shoulder_moves_camera_to_the_other_side() -> void:
	_rig.swap_shoulder()
	await _frames(60)
	assert_almost_eq(_arm.position.x, -_rig.shoulder_offset, 0.01)
	_rig.swap_shoulder()
	await _frames(60)
	assert_almost_eq(_arm.position.x, _rig.shoulder_offset, 0.01)


func test_aiming_zooms_in_and_moves_the_camera_closer() -> void:
	_set_aim(true)
	await _frames(60)
	assert_almost_eq(_camera.fov, _rig.aim_fov, 0.2)
	assert_almost_eq(_arm.position.x, _rig.aim_shoulder_offset, 0.01)
	# The arm only shortens if nothing blocks it; the floor test arena is open.
	assert_true(_arm.spring_length < _rig.hip_arm_length - 1.0, "arm should shorten when aiming")


func test_releasing_aim_returns_to_hip_view() -> void:
	_set_aim(true)
	await _frames(60)
	_set_aim(false)
	await _frames(60)
	assert_almost_eq(_camera.fov, _rig.hip_fov, 0.2)
	assert_almost_eq(_arm.spring_length, _rig.hip_arm_length, 0.1)


func test_recoil_kicks_the_view_up_then_settles() -> void:
	var pivot := _rig.get_node("PitchPivot") as Node3D
	var before := pivot.rotation.x
	_rig.add_recoil(4.0, 1.0)
	assert_almost_eq(pivot.rotation.x - before, deg_to_rad(4.0), 0.001)
	await _frames(120)
	assert_almost_eq(pivot.rotation.x, before, 0.002)
	assert_almost_eq(_rig.rotation.y, _rig.yaw, 0.002)


func test_recoil_is_capped() -> void:
	var pivot := _rig.get_node("PitchPivot") as Node3D
	for i in 20:
		_rig.add_recoil(5.0, 0.0)
	assert_true(pivot.rotation.x <= deg_to_rad(_rig.max_recoil_degrees + 0.01))


func test_mouse_look_turns_and_clamps_pitch() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Some headless display servers refuse to capture the mouse: nothing to test then.
		return
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100.0, 0.0)
	_rig._unhandled_input(motion)
	assert_almost_eq(_rig.yaw, -100.0 * _rig.mouse_sensitivity, 0.0001)
	motion.relative = Vector2(0.0, -100000.0)
	_rig._unhandled_input(motion)
	assert_almost_eq(_rig.pitch, deg_to_rad(_rig.max_pitch_degrees), 0.0001)
	motion.relative = Vector2(0.0, 100000.0)
	_rig._unhandled_input(motion)
	assert_almost_eq(_rig.pitch, deg_to_rad(_rig.min_pitch_degrees), 0.0001)


func test_aiming_lowers_mouse_sensitivity() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	_rig.set_aiming(true)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100.0, 0.0)
	_rig._unhandled_input(motion)
	var expected := -100.0 * _rig.mouse_sensitivity * _rig.aim_sensitivity_scale
	assert_almost_eq(_rig.yaw, expected, 0.0001)


## The player re-applies its aim state to the camera every tick, so aim is driven through it.
func _set_aim(aiming: bool) -> void:
	_player.input_override.aim_pressed = aiming


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
