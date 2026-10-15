extends TestCase
## Real shots traced through the physics world from the actual player scene.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const WALL_FRONT_Z := -9.5

var _world: Node3D
var _player: PlayerController
var _weapon: WeaponController
var _frame: InputFrame
var _shots: Array[ShotResult] = []
var _kicks: Array[Vector2] = []


func before_each() -> void:
	_shots = []
	_kicks = []
	_world = Node3D.new()
	tree.root.add_child(_world)
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(100.0, 1.0, 100.0))  # floor
	_add_box(Vector3(0.0, 2.0, -10.0), Vector3(20.0, 4.0, 1.0))  # wall, front face at z = -9.5
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_world.add_child(_player)
	_frame = InputFrame.new()
	_player.input_override = _frame
	_weapon = _player.weapon
	# A fixed ray straight at the wall, so tests do not depend on the camera.
	_weapon.aim_ray_provider = func() -> AimRay:
		return AimRay.create(Vector3(0.0, 1.6, 3.0), Vector3(0.0, 0.0, -1.0))
	_weapon.shot_fired.connect(func(result: ShotResult) -> void: _shots.append(result))
	_weapon.recoil_kick.connect(
		func(pitch: float, yaw: float) -> void: _kicks.append(Vector2(pitch, yaw))
	)
	_use_perfect_accuracy()
	await _frames(5)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


func test_a_shot_hits_the_wall_where_it_was_aimed() -> void:
	await _click()
	assert_eq(_shots.size(), 1)
	var shot := _shots[0]
	assert_true(shot.hit)
	assert_almost_eq(shot.end.z, WALL_FRONT_Z, 0.05)
	assert_almost_eq(shot.end.x, 0.0, 0.05)
	assert_true(shot.normal.z > 0.9, "wall normal should face the player")


func test_the_muzzle_check_stops_bullets_at_obstacles_the_camera_sees_past() -> void:
	# A thin pillar right in front of the muzzle: the camera ray (x = 0) misses it, the muzzle
	# ray (x = 0.28) does not, so the bullet must stop at the pillar instead of reaching the wall.
	_add_box(Vector3(0.28, 1.3, -1.5), Vector3(0.2, 2.6, 0.2))
	await _frames(3)
	await _click()
	assert_eq(_shots.size(), 1)
	assert_true(_shots[0].hit)
	assert_true(_shots[0].end.z > -1.6 and _shots[0].end.z < -1.3, "stopped at %s" % _shots[0].end)


func test_shots_that_hit_nothing_end_at_maximum_range() -> void:
	_weapon.aim_ray_provider = func() -> AimRay:
		return AimRay.create(Vector3(0.0, 1.6, 3.0), Vector3(0.0, 1.0, 0.0).normalized())
	await _click()
	assert_eq(_shots.size(), 1)
	assert_false(_shots[0].hit)
	assert_almost_eq(_shots[0].distance, _weapon.data.range_meters, 1.0)


func test_each_shot_uses_one_round_and_kicks_the_camera() -> void:
	var before := _weapon.state.magazine
	await _click()
	assert_eq(_weapon.state.magazine, before - 1)
	assert_eq(_kicks.size(), 1)
	assert_almost_eq(_kicks[0].x, _weapon.data.recoil_pitch, 0.0001)
	assert_true(absf(_kicks[0].y) <= _weapon.data.recoil_yaw + 0.0001)


func test_holding_fire_shoots_at_the_weapons_rate() -> void:
	_frame.fire_pressed = true
	await _frames(30)  # half a second
	var expected := 0.5 / _weapon.data.fire_interval() + 1.0
	assert_true(
		absf(_shots.size() - expected) <= 1.0,
		"%d shots, expected ~%.1f" % [_shots.size(), expected]
	)


func test_semi_auto_weapons_need_one_click_per_shot() -> void:
	_weapon.data.automatic = false
	_frame.fire_pressed = true
	await _frames(30)
	assert_eq(_shots.size(), 1, "holding the trigger must not repeat")
	_frame.fire_pressed = false
	await _frames(2)
	_frame.fire_pressed = true
	await _frames(2)
	assert_eq(_shots.size(), 2)


func test_an_empty_magazine_reloads_automatically() -> void:
	_weapon.state.magazine = 0
	_frame.fire_pressed = true
	await _frames(3)
	assert_eq(_weapon.state.status, WeaponState.Status.RELOADING)
	assert_eq(_shots.size(), 0)


func test_reload_key_reloads_even_with_ammo_in_the_magazine() -> void:
	_weapon.state.magazine = 10
	_frame.reload_pressed = true
	await _frames(1)
	_frame.reload_pressed = false
	assert_eq(_weapon.state.status, WeaponState.Status.RELOADING)
	await _frames(ceili((_weapon.data.reload_seconds + 0.2) * 60.0))
	assert_eq(_weapon.state.magazine, _weapon.data.magazine_size)


func test_aiming_groups_shots_tighter_than_hip_fire() -> void:
	var data := _weapon.data
	data.spread_hip = 5.0
	data.spread_aim = 0.2
	data.spread_gain_per_shot = 0.0
	data.rounds_per_minute = 6000.0
	data.magazine_size = 400
	_weapon.state = WeaponState.new(data)
	_weapon.rng.seed = 12345

	_frame.fire_pressed = true
	await _frames(30)
	var hip_spread := _max_horizontal_deviation()

	_shots.clear()
	_frame.aim_pressed = true
	await _frames(30)
	var aim_spread := _max_horizontal_deviation()

	assert_true(hip_spread > 0.3, "hip fire should scatter, got %.3f m" % hip_spread)
	assert_true(aim_spread < 0.2, "aimed fire should be tight, got %.3f m" % aim_spread)


func test_shooting_squares_the_body_up_to_the_camera() -> void:
	_frame.aim_yaw = PI / 2.0
	_frame.fire_pressed = true
	await _frames(60)
	assert_almost_eq(_player.rotation.y, PI / 2.0, 0.05)


func test_cannot_sprint_while_firing() -> void:
	_frame.move = Vector2(0.0, 1.0)
	_frame.sprint = true
	_frame.fire_pressed = true
	await _frames(60)
	assert_almost_eq(_player.horizontal_speed(), _player.config.walk_speed, 0.05)


func test_shot_effects_are_cosmetic_and_clean_themselves_up() -> void:
	await _click()
	assert_true(_count_effects() >= 1, "a tracer should have been spawned")
	await _frames(40)
	assert_eq(_count_effects(), 0, "effects must free themselves")


func _use_perfect_accuracy() -> void:
	var data := _weapon.data.duplicate() as WeaponData
	data.spread_hip = 0.0
	data.spread_aim = 0.0
	data.spread_gain_per_shot = 0.0
	_weapon.data = data
	_weapon.state = WeaponState.new(data)


func _max_horizontal_deviation() -> float:
	var deviation := 0.0
	for shot in _shots:
		if shot.hit:
			deviation = maxf(deviation, absf(shot.end.x))
	return deviation


func _count_effects() -> int:
	var count := 0
	for child in _world.get_children():
		if str(child.name).begins_with("ShotTracer") or str(child.name).begins_with("ShotImpact"):
			count += 1
	return count


## Pulls the trigger for exactly one tick, then lets the effects of that tick play out.
func _click() -> void:
	_frame.fire_pressed = true
	await _frames(1)
	_frame.fire_pressed = false
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func _add_box(center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.WORLD
	body.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	_world.add_child(body)
	return body
