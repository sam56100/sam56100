extends TestCase
## Crafting a heal kit with the real player.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")

var _world: Node3D
var _player: PlayerController
var _frame: InputFrame
var _heal_recipe: Recipe


func before_each() -> void:
	Localization.setup()
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
	_heal_recipe = _player.crafter.recipes[0]
	await _frames(5)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


func test_the_heal_kit_recipe_uses_two_of_the_six_components() -> void:
	var cost := _heal_recipe.cost()
	assert_eq(cost.size(), 2)
	assert_eq(int(cost[CraftComponent.Type.RAG]), 1)
	assert_eq(int(cost[CraftComponent.Type.ALCOHOL]), 1)
	assert_eq(_heal_recipe.result, CraftedItem.Kind.HEAL_KIT)


func test_crafting_is_short_enough_to_do_mid_fight() -> void:
	assert_true(_heal_recipe.craft_seconds <= 2.0)


func test_a_recipe_needing_the_same_component_twice_costs_two_of_it() -> void:
	var recipe := Recipe.new()
	recipe.component_a = CraftComponent.Type.SUGAR
	recipe.component_b = CraftComponent.Type.SUGAR
	assert_eq(int(recipe.cost()[CraftComponent.Type.SUGAR]), 2)


func test_cannot_craft_without_the_components() -> void:
	_player.inventory.add(CraftComponent.Type.RAG, 1)
	assert_false(_player.crafter.begin(_heal_recipe))
	assert_false(_player.crafter.is_crafting())
	assert_eq(_player.inventory.count(CraftComponent.Type.RAG), 1)


func test_crafting_consumes_the_components_and_gives_a_heal_kit() -> void:
	_give_heal_ingredients()
	_player.inventory.add(CraftComponent.Type.BLADE, 1)
	await _press_slot(1)
	assert_true(_player.crafter.is_crafting())
	assert_eq(_player.inventory.total(), 3, "components are only consumed on completion")
	await _frames(ceili((_heal_recipe.craft_seconds + 0.2) * 60.0))
	assert_false(_player.crafter.is_crafting())
	assert_eq(_player.items.count(CraftedItem.Kind.HEAL_KIT), 1)
	assert_eq(_player.inventory.count(CraftComponent.Type.RAG), 0)
	assert_eq(_player.inventory.count(CraftComponent.Type.ALCOHOL), 0)
	assert_eq(_player.inventory.count(CraftComponent.Type.BLADE), 1, "other components are kept")


func test_the_slot_key_does_nothing_unless_the_menu_is_held() -> void:
	_give_heal_ingredients()
	_frame.craft_select = 1
	await _frames(2)
	_frame.craft_select = 0
	assert_false(_player.crafter.is_crafting())


func test_unknown_slots_are_ignored() -> void:
	_give_heal_ingredients()
	await _press_slot(5)
	assert_false(_player.crafter.is_crafting())


func test_the_menu_is_open_only_while_the_key_is_held() -> void:
	_frame.craft_menu_held = true
	await _frames(2)
	assert_true(_player.crafter.menu_open)
	_frame.craft_menu_held = false
	await _frames(2)
	assert_false(_player.crafter.menu_open)


func test_sprinting_firing_or_jumping_interrupts_without_cost() -> void:
	for interrupt in ["sprint", "fire", "jump"]:
		_give_heal_ingredients()
		await _press_slot(1)
		assert_true(_player.crafter.is_crafting(), "%s: started" % interrupt)
		match interrupt:
			"sprint":
				_frame.move = Vector2(0.0, 1.0)
				_frame.sprint = true
			"fire":
				_frame.fire_pressed = true
			"jump":
				_frame.jump_pressed = true
		await _frames(2)
		assert_false(_player.crafter.is_crafting(), "%s: interrupted" % interrupt)
		assert_eq(_player.items.count(CraftedItem.Kind.HEAL_KIT), 0)
		assert_eq(
			_player.inventory.count(CraftComponent.Type.RAG), 1, "%s: nothing consumed" % interrupt
		)
		_frame.move = Vector2.ZERO
		_frame.sprint = false
		_frame.fire_pressed = false
		_frame.jump_pressed = false
		_frame.craft_menu_held = false
		await _frames(5)
		_player.inventory.clear()


func test_taking_damage_interrupts_crafting() -> void:
	_give_heal_ingredients()
	await _press_slot(1)
	assert_true(_player.crafter.is_crafting())
	_player.health.take_damage(10)
	assert_false(_player.crafter.is_crafting())
	assert_eq(_player.inventory.count(CraftComponent.Type.RAG), 1)


func test_cannot_craft_while_another_action_is_running() -> void:
	_give_heal_ingredients()
	var other := Node.new()
	_player.try_begin_action(other)
	await _press_slot(1)
	assert_false(_player.crafter.is_crafting())
	_player.end_action(other)
	other.free()


func test_a_dead_player_cannot_craft() -> void:
	_give_heal_ingredients()
	_player.health.take_damage(100)
	await _press_slot(1)
	assert_false(_player.crafter.is_crafting())


func test_two_kits_can_be_crafted_in_a_row() -> void:
	_player.inventory.add(CraftComponent.Type.RAG, 2)
	_player.inventory.add(CraftComponent.Type.ALCOHOL, 2)
	for i in 2:
		await _press_slot(1)
		await _frames(ceili((_heal_recipe.craft_seconds + 0.2) * 60.0))
	assert_eq(_player.items.count(CraftedItem.Kind.HEAL_KIT), 2)
	assert_eq(_player.inventory.total(), 0)


func _give_heal_ingredients() -> void:
	_player.inventory.add(CraftComponent.Type.RAG, 1)
	_player.inventory.add(CraftComponent.Type.ALCOHOL, 1)


## Holds the menu key and presses a slot number for one tick.
func _press_slot(slot: int) -> void:
	_frame.craft_menu_held = true
	_frame.craft_select = slot
	await _frames(1)
	_frame.craft_select = 0
	await _frames(1)


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
