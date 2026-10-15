extends TestCase
## Damage rules: calculator, health component, hit zones and training dummies.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const DUMMY_Z := -8.0

var _world: Node3D
var _player: PlayerController
var _dummy: TrainingDummy
var _frame: InputFrame
var _hits: Array[HitInfo] = []


func before_each() -> void:
	_hits = []
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

	_dummy = TrainingDummy.new()
	_dummy.position = Vector3(0.0, 0.0, DUMMY_Z)
	_dummy.respawn_seconds = 0.3
	_world.add_child(_dummy)

	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_world.add_child(_player)
	_frame = InputFrame.new()
	_player.input_override = _frame
	var data := _player.weapon.data.duplicate() as WeaponData
	data.spread_hip = 0.0
	data.spread_aim = 0.0
	data.spread_gain_per_shot = 0.0
	data.magazine_size = 200
	_player.weapon.data = data
	_player.weapon.state = WeaponState.new(data)
	_player.weapon.hit_confirmed.connect(func(info: HitInfo) -> void: _hits.append(info))
	await _frames(5)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


# --- pure rules ---


func test_damage_calculator_rounds_and_never_goes_below_one() -> void:
	assert_eq(DamageCalculator.compute(18.0, 2.0), 36)
	assert_eq(DamageCalculator.compute(18.0, 1.0), 18)
	assert_eq(DamageCalculator.compute(18.0, 0.75), 14)
	assert_eq(DamageCalculator.compute(0.1, 0.1), 1)


func test_zone_multipliers_are_ordered_head_torso_limbs() -> void:
	var head := DamageZone.default_multiplier(DamageZone.Kind.HEAD)
	var torso := DamageZone.default_multiplier(DamageZone.Kind.TORSO)
	var limbs := DamageZone.default_multiplier(DamageZone.Kind.LIMBS)
	assert_true(head > torso and torso > limbs)


func test_hits_to_kill() -> void:
	assert_eq(DamageCalculator.hits_to_kill(100, 18), 6)
	assert_eq(DamageCalculator.hits_to_kill(100, 36), 3)
	assert_eq(DamageCalculator.hits_to_kill(100, 14), 8)


func test_health_component_damage_heal_and_limits() -> void:
	var health := HealthComponent.new()
	_world.add_child(health)
	assert_eq(health.current_health, 100)
	assert_eq(health.take_damage(30), 30)
	assert_eq(health.current_health, 70)
	assert_eq(health.heal(50), 30, "healing is capped at max health")
	assert_eq(health.current_health, 100)
	assert_eq(health.heal(10), 0, "nothing to heal at full health")
	assert_eq(health.take_damage(0), 0)
	assert_eq(health.take_damage(-5), 0)
	assert_eq(health.take_damage(500), 100, "damage is capped at the remaining health")
	assert_true(health.is_dead())


func test_health_component_dies_once_and_cannot_be_healed_when_dead() -> void:
	var health := HealthComponent.new()
	_world.add_child(health)
	var deaths := [0]
	health.died.connect(func() -> void: deaths[0] += 1)
	health.take_damage(100)
	health.take_damage(100)
	assert_eq(deaths[0], 1)
	assert_eq(health.heal(50), 0)
	health.reset()
	assert_eq(health.current_health, 100)
	assert_false(health.is_dead())


func test_health_component_reports_changes() -> void:
	var health := HealthComponent.new()
	_world.add_child(health)
	var last := [-1, -1]
	health.changed.connect(
		func(current: int, maximum: int) -> void:
			last[0] = current
			last[1] = maximum
	)
	health.take_damage(25)
	assert_eq(last, [75, 100])


# --- zones and dummies, with real shots ---


func test_a_torso_shot_deals_the_base_damage() -> void:
	await _shoot_at(Vector3(0.0, 1.15, DUMMY_Z))
	assert_eq(_dummy.health.current_health, 100 - 18)
	assert_eq(_hits.size(), 1)
	assert_eq(_hits[0].zone, DamageZone.Kind.TORSO)


func test_a_headshot_deals_double_damage() -> void:
	await _shoot_at(Vector3(0.0, 1.62, DUMMY_Z))
	assert_eq(_hits.size(), 1)
	assert_eq(_hits[0].zone, DamageZone.Kind.HEAD)
	assert_eq(_dummy.health.current_health, 100 - 36)


func test_a_leg_shot_deals_reduced_damage() -> void:
	await _shoot_at(Vector3(0.0, 0.4, DUMMY_Z))
	assert_eq(_hits.size(), 1)
	assert_eq(_hits[0].zone, DamageZone.Kind.LIMBS)
	assert_eq(_dummy.health.current_health, 100 - 14)


func test_torso_kill_takes_the_expected_number_of_hits() -> void:
	_dummy.respawn_seconds = 100.0
	_player.weapon.aim_ray_provider = _aim_at(Vector3(0.0, 1.15, DUMMY_Z))
	_frame.fire_pressed = true
	await _frames(120)
	_frame.fire_pressed = false
	assert_eq(_hits.size(), DamageCalculator.hits_to_kill(100, 18), "bullets stop at a dead target")
	assert_true(_dummy.is_dead())
	assert_true(_hits[_hits.size() - 1].killed)
	for i in _hits.size() - 1:
		assert_false(_hits[i].killed, "only the last hit kills")


func test_head_kills_faster_than_torso_and_limbs() -> void:
	assert_true(DamageCalculator.hits_to_kill(100, 36) < DamageCalculator.hits_to_kill(100, 18))
	assert_true(DamageCalculator.hits_to_kill(100, 18) < DamageCalculator.hits_to_kill(100, 14))


func test_a_dummy_that_respawns_during_its_fall_stands_up_for_good() -> void:
	# Respawn delay shorter than the fall animation: the fall must not resume after respawning.
	_dummy.respawn_seconds = 0.1
	_dummy.health.take_damage(100)
	await _frames(60)
	assert_false(_dummy.is_dead())
	var visuals := _dummy.get_node("Visuals") as Node3D
	assert_almost_eq(visuals.rotation.x, 0.0, 0.001, "dummy must stay upright after respawning")


func test_a_dead_dummy_can_no_longer_be_shot_then_respawns() -> void:
	_dummy.respawn_seconds = 1.0
	_dummy.health.take_damage(100)
	await _frames(5)
	await _shoot_at(Vector3(0.0, 1.15, DUMMY_Z))
	assert_eq(_hits.size(), 0, "a dead target takes no hits")
	await _frames(70)
	assert_false(_dummy.is_dead())
	assert_eq(_dummy.health.current_health, 100)
	await _shoot_at(Vector3(0.0, 1.15, DUMMY_Z))
	assert_eq(_hits.size(), 1, "the respawned dummy can be shot again")


func test_shots_that_hit_the_world_do_not_confirm_a_hit() -> void:
	await _shoot_at(Vector3(5.0, 1.0, DUMMY_Z))
	assert_eq(_hits.size(), 0)
	assert_eq(_dummy.health.current_health, 100)


func test_damage_numbers_are_spawned_and_clean_themselves_up() -> void:
	await _shoot_at(Vector3(0.0, 1.15, DUMMY_Z))
	assert_true(_count_named("DamageNumber") >= 1)
	await _frames(70)
	assert_eq(_count_named("DamageNumber"), 0)


func _aim_at(point: Vector3) -> Callable:
	var origin := Vector3(0.0, 1.6, 3.0)
	return func() -> AimRay: return AimRay.create(origin, point - origin)


func _shoot_at(point: Vector3) -> void:
	_player.weapon.aim_ray_provider = _aim_at(point)
	_frame.fire_pressed = true
	await _frames(1)
	_frame.fire_pressed = false
	await _frames(3)


func _count_named(prefix: String) -> int:
	var count := 0
	for child in _world.get_children():
		if str(child.name).begins_with(prefix):
			count += 1
	return count


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
