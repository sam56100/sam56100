extends TestCase
## Opening crates with the real player and physics.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")

var _world: Node3D
var _player: PlayerController
var _crate: LootCrate
var _frame: InputFrame
var _loot_events: Array[Dictionary] = []


func before_each() -> void:
	_loot_events = []
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

	_crate = LootCrate.new()
	_crate.position = Vector3(0.0, 0.0, -1.5)
	_crate.refill_seconds = 1.0
	_crate.rng.seed = 7
	_world.add_child(_crate)

	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_world.add_child(_player)
	_frame = InputFrame.new()
	_player.input_override = _frame
	_player.loot_collected.connect(func(loot: Dictionary) -> void: _loot_events.append(loot))
	await _frames(5)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


func test_a_crate_in_range_is_offered_as_a_target() -> void:
	assert_true(_player.interactor.has_target())
	assert_eq(_player.interactor.get_prompt(), "Hold [E] to open")


func test_holding_interact_opens_the_crate_and_gives_components() -> void:
	_frame.interact_held = true
	await _frames(ceili((_crate.open_seconds + 0.2) * 60.0))
	assert_true(_crate.is_open)
	assert_eq(_loot_events.size(), 1)
	assert_true(_player.inventory.total() >= 2, "got %d components" % _player.inventory.total())
	assert_false(_player.interactor.is_interacting())


func test_the_crate_is_quick_to_open() -> void:
	assert_true(_crate.open_seconds <= 1.0, "design: crates open in about a second or less")


func test_releasing_the_key_cancels_without_loot() -> void:
	_frame.interact_held = true
	await _frames(20)
	assert_true(_player.interactor.is_interacting())
	assert_true(_player.interactor.progress() > 0.0)
	_frame.interact_held = false
	await _frames(3)
	assert_false(_player.interactor.is_interacting())
	assert_false(_crate.is_open)
	assert_eq(_player.inventory.total(), 0)


func test_walking_out_of_range_cancels() -> void:
	_frame.interact_held = true
	await _frames(20)
	_player.global_position = Vector3(8.0, 0.05, 8.0)
	await _frames(ceili((_crate.open_seconds + 0.3) * 60.0))
	assert_false(_crate.is_open)
	assert_eq(_player.inventory.total(), 0)


func test_firing_or_jumping_interrupts_the_opening() -> void:
	_frame.interact_held = true
	_frame.fire_pressed = true
	await _frames(ceili((_crate.open_seconds + 0.3) * 60.0))
	assert_false(_crate.is_open)


func test_an_opened_crate_cannot_be_opened_again_until_it_refills() -> void:
	_frame.interact_held = true
	await _frames(ceili((_crate.open_seconds + 0.2) * 60.0))
	var first_total := _player.inventory.total()
	await _frames(20)
	assert_eq(_player.inventory.total(), first_total, "an open crate gives nothing more")
	assert_false(_player.interactor.has_target())
	await _frames(70)  # refill_seconds = 1.0
	assert_false(_crate.is_open, "the crate refilled")


func test_a_refilled_crate_can_be_looted_again() -> void:
	_frame.interact_held = true
	await _frames(ceili((_crate.open_seconds + 0.2) * 60.0))
	await _frames(70)
	await _frames(ceili((_crate.open_seconds + 0.2) * 60.0))
	assert_eq(_loot_events.size(), 2)


func test_the_nearest_crate_is_chosen() -> void:
	var far := LootCrate.new()
	far.position = Vector3(1.2, 0.0, -1.5)
	_world.add_child(far)
	await _frames(3)
	_frame.interact_held = true
	await _frames(ceili((_crate.open_seconds + 0.2) * 60.0))
	assert_true(_crate.is_open, "the closer crate opens first")
	assert_false(far.is_open)


func test_only_one_timed_action_runs_at_a_time() -> void:
	var other := Node.new()
	assert_true(_player.try_begin_action(other))
	_frame.interact_held = true
	await _frames(ceili((_crate.open_seconds + 0.3) * 60.0))
	assert_false(_crate.is_open, "busy with another action")
	_player.end_action(other)
	await _frames(ceili((_crate.open_seconds + 0.3) * 60.0))
	assert_true(_crate.is_open)
	other.free()


func test_a_dead_player_cannot_loot() -> void:
	_player.health.take_damage(100)
	_frame.interact_held = true
	await _frames(ceili((_crate.open_seconds + 0.3) * 60.0))
	assert_false(_crate.is_open)


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
