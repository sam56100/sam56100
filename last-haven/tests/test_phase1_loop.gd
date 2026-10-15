extends TestCase
## The whole phase 1 goal, end to end: take damage, open crates, craft a heal kit, heal.

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

	# Two crates with known contents so the scenario is deterministic: rags, then alcohol.
	_world.add_child(_make_crate(CraftComponent.Type.RAG, Vector3(-1.5, 0.0, -1.5)))
	_world.add_child(_make_crate(CraftComponent.Type.ALCOHOL, Vector3(1.5, 0.0, -1.5)))

	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_world.add_child(_player)
	_frame = InputFrame.new()
	_player.input_override = _frame
	await _frames(5)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


func test_get_hurt_loot_craft_a_heal_kit_and_heal_up() -> void:
	# 1. Get hurt (a fight, in real life).
	_player.health.take_damage(70)
	assert_eq(_player.health.current_health, 30)

	# 2. Loot: stand next to each crate and hold the interact key.
	_player.global_position = Vector3(-1.2, 0.05, 0.0)
	await _hold_interact()
	assert_eq(_player.inventory.count(CraftComponent.Type.RAG), 1)
	_player.global_position = Vector3(1.2, 0.05, 0.0)
	await _hold_interact()
	assert_eq(_player.inventory.count(CraftComponent.Type.ALCOHOL), 1)

	# 3. Craft the heal kit from the menu (hold Tab, press 1).
	_frame.craft_menu_held = true
	_frame.craft_select = 1
	await _frames(1)
	_frame.craft_select = 0
	await _frames(ceili((_player.crafter.recipes[0].craft_seconds + 0.2) * 60.0))
	_frame.craft_menu_held = false
	assert_eq(_player.items.count(CraftedItem.Kind.HEAL_KIT), 1)
	assert_eq(_player.inventory.total(), 0, "the ingredients were consumed")

	# 4. Use it.
	_frame.use_heal_pressed = true
	await _frames(1)
	_frame.use_heal_pressed = false
	await _frames(ceili((_player.item_user.use_seconds + 0.2) * 60.0))
	assert_eq(_player.health.current_health, 30 + _player.item_user.heal_amount)
	assert_eq(_player.items.count(CraftedItem.Kind.HEAL_KIT), 0)


func _make_crate(type: CraftComponent.Type, at: Vector3) -> LootCrate:
	var table := LootTable.new()
	table.weights = {type: 1.0}
	table.picks_min = 1
	table.picks_max = 1
	var crate := LootCrate.new()
	crate.loot_table = table
	crate.position = at
	return crate


func _hold_interact() -> void:
	_frame.interact_held = true
	await _frames(ceili((0.8 + 0.3) * 60.0))
	_frame.interact_held = false
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
