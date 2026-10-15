extends TestCase
## Using heal kits with the real player.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")

var _world: Node3D
var _player: PlayerController
var _frame: InputFrame


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
	_frame = InputFrame.new()
	_player.input_override = _frame
	await _frames(5)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


func test_a_heal_kit_restores_health_and_is_used_up() -> void:
	_player.items.add(CraftedItem.Kind.HEAL_KIT)
	_player.health.take_damage(70)
	await _press_heal()
	assert_true(_player.item_user.is_using())
	assert_eq(_player.health.current_health, 30, "healing only happens when the use completes")
	await _frames(ceili((_player.item_user.use_seconds + 0.2) * 60.0))
	assert_eq(_player.health.current_health, 30 + _player.item_user.heal_amount)
	assert_eq(_player.items.count(CraftedItem.Kind.HEAL_KIT), 0)
	assert_false(_player.item_user.is_using())


func test_healing_never_goes_above_the_maximum() -> void:
	_player.items.add(CraftedItem.Kind.HEAL_KIT)
	_player.health.take_damage(20)
	await _press_heal()
	await _frames(ceili((_player.item_user.use_seconds + 0.2) * 60.0))
	assert_eq(_player.health.current_health, _player.health.max_health)


func test_a_kit_is_not_wasted_at_full_health() -> void:
	_player.items.add(CraftedItem.Kind.HEAL_KIT)
	await _press_heal()
	assert_false(_player.item_user.is_using())
	assert_eq(_player.items.count(CraftedItem.Kind.HEAL_KIT), 1)


func test_nothing_happens_without_a_kit() -> void:
	_player.health.take_damage(50)
	await _press_heal()
	assert_false(_player.item_user.is_using())
	assert_eq(_player.health.current_health, 50)


func test_moving_fast_firing_or_jumping_interrupts_and_keeps_the_kit() -> void:
	for interrupt in ["sprint", "fire", "jump"]:
		_player.items.add(CraftedItem.Kind.HEAL_KIT)
		_player.health.take_damage(30)
		await _press_heal()
		assert_true(_player.item_user.is_using(), "%s: started" % interrupt)
		match interrupt:
			"sprint":
				_frame.move = Vector2(0.0, 1.0)
				_frame.sprint = true
			"fire":
				_frame.fire_pressed = true
			"jump":
				_frame.jump_pressed = true
		await _frames(ceili((_player.item_user.use_seconds + 0.2) * 60.0))
		assert_false(_player.item_user.is_using(), "%s: interrupted" % interrupt)
		assert_eq(_player.items.count(CraftedItem.Kind.HEAL_KIT), 1, "%s: kit kept" % interrupt)
		assert_eq(_player.health.current_health, 70, "%s: no healing" % interrupt)
		_frame.move = Vector2.ZERO
		_frame.sprint = false
		_frame.fire_pressed = false
		_frame.jump_pressed = false
		_player.health.reset()
		_player.items.remove(CraftedItem.Kind.HEAL_KIT)
		await _frames(5)


func test_being_hit_while_healing_cancels_it() -> void:
	_player.items.add(CraftedItem.Kind.HEAL_KIT)
	_player.health.take_damage(30)
	await _press_heal()
	_player.health.take_damage(10)
	assert_false(_player.item_user.is_using())
	await _frames(ceili((_player.item_user.use_seconds + 0.2) * 60.0))
	assert_eq(_player.health.current_health, 60)
	assert_eq(_player.items.count(CraftedItem.Kind.HEAL_KIT), 1)


func test_cannot_heal_while_crafting() -> void:
	_player.inventory.add(CraftComponent.Type.RAG, 1)
	_player.inventory.add(CraftComponent.Type.ALCOHOL, 1)
	_player.items.add(CraftedItem.Kind.HEAL_KIT)
	_player.health.take_damage(30)
	assert_true(_player.crafter.begin(_player.crafter.recipes[0]))
	await _press_heal()
	assert_false(_player.item_user.is_using())


func test_a_dead_player_cannot_heal() -> void:
	_player.items.add(CraftedItem.Kind.HEAL_KIT)
	_player.health.take_damage(100)
	await _press_heal()
	assert_false(_player.item_user.is_using())


func _press_heal() -> void:
	_frame.use_heal_pressed = true
	await _frames(1)
	_frame.use_heal_pressed = false
	await _frames(1)


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
