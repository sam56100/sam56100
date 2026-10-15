extends TestCase
## The real main scene, wired together: world, player, HUD, respawn.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var _main: Node


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	tree.root.add_child(_main)
	await _frames(10)


func after_each() -> void:
	_main.queue_free()
	await tree.process_frame


func test_main_scene_builds_the_world_the_player_and_the_hud() -> void:
	assert_true(_main.get_node_or_null("Map") != null)
	assert_true(_main.get_node_or_null("Player") != null)
	assert_true(_main.get_node_or_null("Hud") != null)
	assert_true(_main.get_node_or_null("DebugOverlay") != null)


func test_player_lands_on_the_spawn_point_and_is_alive() -> void:
	var player := _main.get_node("Player") as PlayerController
	assert_false(player.is_dead())
	assert_true(player.is_on_floor())
	var spawn := (_main.get_node("Map") as GreyboxMap).get_spawn_transform().origin
	assert_almost_eq(player.global_position.x, spawn.x, 0.5)
	assert_almost_eq(player.global_position.z, spawn.z, 0.5)


func test_dying_respawns_the_player_at_the_spawn_point() -> void:
	var player := _main.get_node("Player") as PlayerController
	player.global_position = Vector3(5.0, 0.2, 5.0)
	player.health.take_damage(100)
	assert_true(player.is_dead())
	await _frames(ceili((Main.RESPAWN_DELAY + 0.5) * 60.0))
	assert_false(player.is_dead())
	assert_eq(player.health.current_health, player.health.max_health)
	var spawn := (_main.get_node("Map") as GreyboxMap).get_spawn_transform().origin
	assert_almost_eq(player.global_position.z, spawn.z, 0.5)


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
