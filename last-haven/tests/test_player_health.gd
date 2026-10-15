extends TestCase
## The player's own health: damage, death, respawn.

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
	await _frames(10)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


func test_player_starts_at_full_health() -> void:
	assert_eq(_player.health.current_health, _player.health.max_health)
	assert_false(_player.is_dead())


func test_debug_damage_key_hurts_the_player() -> void:
	_frame.debug_damage_pressed = true
	await _frames(1)
	_frame.debug_damage_pressed = false
	await _frames(1)
	assert_eq(_player.health.current_health, 70)


func test_a_dead_player_cannot_move_or_shoot() -> void:
	var shots := [0]
	_player.weapon.shot_fired.connect(func(_result: ShotResult) -> void: shots[0] += 1)
	_player.health.take_damage(100)
	assert_true(_player.is_dead())
	_frame.move = Vector2(0.0, 1.0)
	_frame.sprint = true
	_frame.fire_pressed = true
	await _frames(60)
	assert_almost_eq(_player.horizontal_speed(), 0.0, 0.05)
	assert_eq(shots[0], 0)


func test_a_dead_player_cannot_be_healed_but_a_hurt_one_can() -> void:
	_player.health.take_damage(40)
	assert_eq(_player.health.heal(25), 25)
	_player.health.take_damage(100)
	assert_eq(_player.health.heal(25), 0)


func test_respawn_restores_everything() -> void:
	_player.weapon.state.magazine = 3
	_player.weapon.state.reserve = 0
	_player.health.take_damage(100)
	_player.position = Vector3(10.0, 0.05, 10.0)
	_player.respawn(Transform3D(Basis.IDENTITY, Vector3(0.0, 0.05, 0.0)))
	await _frames(5)
	assert_false(_player.is_dead())
	assert_eq(_player.health.current_health, _player.health.max_health)
	assert_eq(_player.weapon.state.magazine, _player.weapon.data.magazine_size)
	assert_eq(_player.weapon.state.reserve, _player.weapon.data.reserve_ammo)
	assert_almost_eq(_player.global_position.x, 0.0, 0.01)
	assert_eq(_player.stance, PlayerController.Stance.STANDING)
	# Alive again: input works.
	_frame.move = Vector2(0.0, 1.0)
	await _frames(40)
	assert_true(_player.horizontal_speed() > 3.0)


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
