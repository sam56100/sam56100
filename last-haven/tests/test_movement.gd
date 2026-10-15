extends TestCase
## Real physics tests for the player locomotion, using the actual player scene.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const FLOOR_HALF_SIZE := 50.0

var _world: Node3D
var _player: PlayerController


func before_each() -> void:
	_world = Node3D.new()
	tree.root.add_child(_world)
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(FLOOR_HALF_SIZE * 2.0, 1.0, FLOOR_HALF_SIZE * 2.0))
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_world.add_child(_player)
	# Let the player settle on the floor so is_on_floor() is true.
	await _hold(InputFrame.new(), 10)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


func test_walk_reaches_walk_speed() -> void:
	await _hold(_forward(false), 60)
	assert_almost_eq(_player.horizontal_speed(), _player.config.walk_speed, 0.05)


func test_sprint_is_faster_than_walk() -> void:
	await _hold(_forward(true), 60)
	assert_almost_eq(_player.horizontal_speed(), _player.config.sprint_speed, 0.05)
	assert_true(_player.config.sprint_speed > _player.config.walk_speed)


func test_sprint_requires_forward_intent() -> void:
	var frame := InputFrame.new()
	frame.sprint = true
	frame.move = Vector2(0.0, -1.0)  # backwards
	await _hold(frame, 60)
	assert_almost_eq(_player.horizontal_speed(), _player.config.walk_speed, 0.05)


func test_stops_when_input_released() -> void:
	await _hold(_forward(false), 60)
	await _hold(InputFrame.new(), 30)
	assert_almost_eq(_player.horizontal_speed(), 0.0, 0.05)


func test_crouch_shrinks_body_and_slows_down() -> void:
	await _toggle_crouch()
	assert_eq(_player.stance, PlayerController.Stance.CROUCHING)
	var capsule := _player.get_node("CollisionShape3D").shape as CapsuleShape3D
	assert_almost_eq(capsule.height, _player.config.crouch_height, 0.001)
	await _hold(_forward(false), 60)
	assert_almost_eq(_player.horizontal_speed(), _player.config.crouch_speed, 0.05)


func test_toggle_crouch_twice_stands_up_again() -> void:
	await _toggle_crouch()
	await _toggle_crouch()
	assert_eq(_player.stance, PlayerController.Stance.STANDING)
	var capsule := _player.get_node("CollisionShape3D").shape as CapsuleShape3D
	assert_almost_eq(capsule.height, _player.config.stand_height, 0.001)


func test_jump_reaches_expected_height() -> void:
	var frame := InputFrame.new()
	frame.jump_pressed = true
	_player.input_override = frame
	await tree.physics_frame
	frame.jump_pressed = false
	var apex := 0.0
	for i in 60:
		await tree.physics_frame
		apex = maxf(apex, _player.global_position.y)
	var expected := pow(_player.config.jump_velocity, 2.0) / (2.0 * _player.config.gravity)
	assert_almost_eq(apex, expected, 0.1)


func test_player_lands_back_on_the_floor() -> void:
	var frame := InputFrame.new()
	frame.jump_pressed = true
	_player.input_override = frame
	await tree.physics_frame
	frame.jump_pressed = false
	await _hold(frame, 90)
	assert_true(_player.is_on_floor())
	assert_almost_eq(_player.global_position.y, 0.0, 0.05)


func test_jump_while_crouched_only_stands_up() -> void:
	await _toggle_crouch()
	var frame := InputFrame.new()
	frame.jump_pressed = true
	_player.input_override = frame
	await tree.physics_frame
	frame.jump_pressed = false
	await _hold(frame, 5)
	assert_eq(_player.stance, PlayerController.Stance.STANDING)
	assert_almost_eq(_player.global_position.y, 0.0, 0.05, "should not have left the ground")


func test_cannot_stand_up_under_a_low_beam() -> void:
	await _toggle_crouch()
	# Beam whose underside is 1.4 m above the floor: crouch (1.2 m) fits, standing (1.8 m) does not.
	var beam := _add_box(Vector3(0.0, 1.6, 0.0), Vector3(4.0, 0.4, 4.0))
	await _hold(InputFrame.new(), 3)
	await _toggle_crouch()
	assert_eq(
		_player.stance, PlayerController.Stance.CROUCHING, "must stay crouched under the beam"
	)
	beam.free()
	await _hold(InputFrame.new(), 3)
	await _toggle_crouch()
	assert_eq(_player.stance, PlayerController.Stance.STANDING, "can stand once the beam is gone")


func test_movement_is_relative_to_camera_yaw() -> void:
	var frame := _forward(false)
	frame.aim_yaw = PI / 2.0  # camera looks toward -X
	await _hold(frame, 30)
	assert_true(_player.velocity.x < -3.0, "should move toward -X, velocity %s" % _player.velocity)
	assert_almost_eq(_player.velocity.z, 0.0, 0.05)


func test_body_turns_toward_movement_direction() -> void:
	var frame := InputFrame.new()
	frame.move = Vector2(1.0, 0.0)  # strafe right with camera facing -Z
	await _hold(frame, 60)
	assert_almost_eq(_player.rotation.y, -PI / 2.0, 0.05)


func test_aiming_caps_walking_speed() -> void:
	var frame := _forward(false)
	frame.aim_pressed = true
	await _hold(frame, 60)
	assert_almost_eq(_player.horizontal_speed(), _player.config.aim_speed, 0.05)
	assert_true(_player.config.aim_speed < _player.config.walk_speed)


func test_cannot_sprint_while_aiming() -> void:
	var frame := _forward(true)
	frame.aim_pressed = true
	await _hold(frame, 60)
	assert_almost_eq(_player.horizontal_speed(), _player.config.aim_speed, 0.05)


func test_body_squares_up_to_camera_while_aiming() -> void:
	var frame := InputFrame.new()
	frame.aim_pressed = true
	frame.aim_yaw = PI / 2.0
	await _hold(frame, 60)
	assert_almost_eq(_player.rotation.y, PI / 2.0, 0.05, "should face the camera direction")


func test_body_keeps_facing_the_camera_when_strafing_in_aim() -> void:
	var frame := InputFrame.new()
	frame.aim_pressed = true
	frame.move = Vector2(1.0, 0.0)  # strafe right, camera facing -Z
	await _hold(frame, 60)
	assert_almost_eq(_player.rotation.y, 0.0, 0.05, "strafing in aim must not turn the body")


func _forward(sprint: bool) -> InputFrame:
	var frame := InputFrame.new()
	frame.move = Vector2(0.0, 1.0)
	frame.sprint = sprint
	return frame


## Holds the given intent for a number of physics ticks.
func _hold(frame: InputFrame, ticks: int) -> void:
	_player.input_override = frame
	for i in ticks:
		await tree.physics_frame


func _toggle_crouch() -> void:
	var frame := InputFrame.new()
	frame.crouch_toggle_pressed = true
	_player.input_override = frame
	await tree.physics_frame
	frame.crouch_toggle_pressed = false
	await tree.physics_frame


func _add_box(center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	_world.add_child(body)
	return body
