extends TestCase
## The test arena must build, be solid and give the player a valid spawn point.

var _map: GreyboxMap


func before_each() -> void:
	_map = GreyboxMap.new()
	tree.root.add_child(_map)
	await tree.process_frame


func after_each() -> void:
	_map.queue_free()
	await tree.process_frame


func test_map_builds_static_bodies_on_the_world_layer() -> void:
	var bodies := _map.get_children().filter(func(node: Node) -> bool: return node is StaticBody3D)
	assert_true(bodies.size() >= 20, "expected a populated arena, got %d bodies" % bodies.size())
	for body in bodies:
		assert_eq((body as StaticBody3D).collision_layer, PhysicsLayers.WORLD)


func test_spawn_is_inside_the_arena() -> void:
	var spawn := _map.get_spawn_transform().origin
	assert_true(absf(spawn.x) < GreyboxMap.ARENA_HALF_SIZE)
	assert_true(absf(spawn.z) < GreyboxMap.ARENA_HALF_SIZE)


func test_spawn_has_ground_below_and_free_space_above() -> void:
	await tree.physics_frame
	var space := _map.get_world_3d().direct_space_state
	var origin := _map.get_spawn_transform().origin
	var down := PhysicsRayQueryParameters3D.create(
		origin + Vector3.UP * 2.0, origin + Vector3.DOWN * 2.0
	)
	var hit_below := space.intersect_ray(down)
	assert_false(hit_below.is_empty(), "no ground under the spawn")
	var up := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.UP * 5.0)
	assert_true(space.intersect_ray(up).is_empty(), "something blocks the spawn from above")


func test_training_range_has_shootable_dummies() -> void:
	var dummies := _map.get_children().filter(
		func(node: Node) -> bool: return node is TrainingDummy
	)
	assert_true(dummies.size() >= 5, "expected a training range, got %d dummies" % dummies.size())
	for dummy in dummies:
		assert_false((dummy as TrainingDummy).is_dead())
