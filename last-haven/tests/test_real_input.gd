extends TestCase
## The real keyboard/mouse path (no injected InputFrame): actions are pressed on the Input
## singleton exactly as the engine does for real key presses.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")

var _world: Node3D
var _player: PlayerController
var _rig: CameraRig


func before_each() -> void:
	_release_everything()
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
	_rig = _player.get_node("CameraRig") as CameraRig
	await _frames(10)


func after_each() -> void:
	_release_everything()
	_world.queue_free()
	await tree.process_frame


func test_every_gameplay_action_is_registered_with_a_binding() -> void:
	for action in [
		InputActions.MOVE_FORWARD,
		InputActions.MOVE_BACK,
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.SPRINT,
		InputActions.JUMP,
		InputActions.CROUCH,
		InputActions.AIM,
		InputActions.FIRE,
		InputActions.RELOAD,
		InputActions.INTERACT,
		InputActions.CRAFT_MENU,
		InputActions.USE_HEAL,
		InputActions.SHOULDER_SWAP,
		InputActions.craft_slot(1),
		InputActions.craft_slot(5),
	]:
		assert_true(InputMap.has_action(action), "missing action %s" % action)
		assert_false(InputMap.action_get_events(action).is_empty(), "%s has no key" % action)


func test_bindings_are_physical_keys_so_azerty_and_qwerty_both_work() -> void:
	for action in [InputActions.MOVE_FORWARD, InputActions.MOVE_LEFT, InputActions.JUMP]:
		var event := InputMap.action_get_events(action)[0] as InputEventKey
		assert_true(event.physical_keycode != KEY_NONE, "%s must use a physical keycode" % action)
		assert_eq(event.keycode, KEY_NONE, "%s must not depend on the layout" % action)


func test_forward_key_moves_the_player() -> void:
	Input.action_press(InputActions.MOVE_FORWARD)
	await _frames(60)
	assert_almost_eq(_player.horizontal_speed(), _player.config.walk_speed, 0.1)
	assert_true(_player.global_position.z < -1.0, "moved toward -Z")


func test_sprint_key_with_forward_runs() -> void:
	Input.action_press(InputActions.MOVE_FORWARD)
	Input.action_press(InputActions.SPRINT)
	await _frames(60)
	assert_almost_eq(_player.horizontal_speed(), _player.config.sprint_speed, 0.1)


func test_left_click_fires_and_r_reloads() -> void:
	var shots := [0]
	_player.weapon.shot_fired.connect(func(_result: ShotResult) -> void: shots[0] += 1)
	Input.action_press(InputActions.FIRE)
	await _frames(20)
	Input.action_release(InputActions.FIRE)
	assert_true(shots[0] >= 2, "holding the trigger fires (%d shots)" % shots[0])
	var after_fire := _player.weapon.state.magazine
	Input.action_press(InputActions.RELOAD)
	await _frames(2)
	Input.action_release(InputActions.RELOAD)
	assert_eq(_player.weapon.state.status, WeaponState.Status.RELOADING)
	assert_true(after_fire < _player.weapon.data.magazine_size)


func test_right_click_aims() -> void:
	Input.action_press(InputActions.AIM)
	await _frames(60)
	assert_almost_eq(_player.get_camera().fov, _rig.aim_fov, 0.3)


func test_the_use_heal_key_uses_a_kit() -> void:
	_player.items.add(CraftedItem.Kind.HEAL_KIT)
	_player.health.take_damage(40)
	Input.action_press(InputActions.USE_HEAL)
	await _frames(2)
	Input.action_release(InputActions.USE_HEAL)
	assert_true(_player.item_user.is_using())


func test_tab_and_number_key_craft() -> void:
	_player.inventory.add(CraftComponent.Type.RAG, 1)
	_player.inventory.add(CraftComponent.Type.ALCOHOL, 1)
	Input.action_press(InputActions.CRAFT_MENU)
	await _frames(2)
	Input.action_press(InputActions.craft_slot(1))
	await _frames(2)
	Input.action_release(InputActions.craft_slot(1))
	assert_true(_player.crafter.is_crafting())


func test_escape_releases_the_mouse_and_the_next_click_is_not_a_shot() -> void:
	var shots := [0]
	_player.weapon.shot_fired.connect(func(_result: ShotResult) -> void: shots[0] += 1)
	assert_true(_rig.accepts_gameplay_clicks())

	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	_rig._unhandled_input(escape)
	assert_false(_rig.gameplay_input)
	Input.action_press(InputActions.FIRE)
	await _frames(15)
	assert_eq(shots[0], 0, "no shooting while the mouse is released")

	# The click that takes the mouse back: no shot while that button stays down.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_rig._unhandled_input(click)
	assert_true(_rig.gameplay_input)
	await _frames(15)
	assert_eq(shots[0], 0, "the recapturing click is swallowed")

	# Released, then a fresh press shoots.
	Input.action_release(InputActions.FIRE)
	click.pressed = false
	_rig._unhandled_input(click)
	await _frames(2)
	Input.action_press(InputActions.FIRE)
	await _frames(10)
	assert_true(shots[0] >= 1, "shooting works again after releasing and pressing")


func test_the_mouse_does_not_turn_the_view_while_released() -> void:
	_rig.release_mouse()
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(200.0, 0.0)
	_rig._unhandled_input(motion)
	assert_almost_eq(_rig.yaw, 0.0, 0.0001)
	_rig.take_mouse()
	_rig._unhandled_input(motion)
	assert_true(_rig.yaw < 0.0)


func _release_everything() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
