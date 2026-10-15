class_name GreyboxMap
extends Node3D
## Procedural grey-box test arena (60 x 60 m).
##
## Built from code instead of a hand-written scene so the layout stays readable and diffable, and
## so a headless dedicated server can build the exact same collision world later.
## Contains the shapes needed to judge movement: low cover (crouch height), high walls, a low beam
## (stand blocked, crouch passes), a ramp up to a platform, and scattered crates.

const ARENA_HALF_SIZE := 30.0
const WALL_HEIGHT := 4.0
const WALL_THICKNESS := 1.0

const GROUND_COLOR := Color(0.36, 0.38, 0.37)
const WALL_COLOR := Color(0.22, 0.24, 0.26)
const LOW_COVER_COLOR := Color(0.78, 0.56, 0.2)
const HIGH_COVER_COLOR := Color(0.33, 0.48, 0.68)
const RAMP_COLOR := Color(0.55, 0.7, 0.4)
const BEAM_COLOR := Color(0.7, 0.3, 0.3)
const CRATE_COLOR := Color(0.6, 0.5, 0.4)

const _GRID_TEXTURE_SIZE := 64
const _GRID_LINE_PIXELS := 2
const _GRID_WORLD_METERS := 2.0

var _materials: Dictionary = {}
var _grid_texture: ImageTexture


func _ready() -> void:
	_grid_texture = _make_grid_texture()
	_build_ground_and_walls()
	_build_low_cover()
	_build_high_cover()
	_build_low_beam()
	_build_ramp_and_platform()
	_build_crates()


## Where the player starts: south edge of the arena, facing north (-Z).
func get_spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0.0, 0.1, ARENA_HALF_SIZE - 8.0))


func _build_ground_and_walls() -> void:
	var span := ARENA_HALF_SIZE * 2.0
	_add_box("Ground", Vector3(0.0, -0.5, 0.0), Vector3(span, 1.0, span), GROUND_COLOR)
	var wall_y := WALL_HEIGHT * 0.5
	var edge := ARENA_HALF_SIZE + WALL_THICKNESS * 0.5
	var long_wall := Vector3(span + 2.0 * WALL_THICKNESS, WALL_HEIGHT, WALL_THICKNESS)
	var side_wall := Vector3(WALL_THICKNESS, WALL_HEIGHT, span)
	_add_box("WallNorth", Vector3(0.0, wall_y, -edge), long_wall, WALL_COLOR)
	_add_box("WallSouth", Vector3(0.0, wall_y, edge), long_wall, WALL_COLOR)
	_add_box("WallWest", Vector3(-edge, wall_y, 0.0), side_wall, WALL_COLOR)
	_add_box("WallEast", Vector3(edge, wall_y, 0.0), side_wall, WALL_COLOR)


## Waist-high cover (1.0 m): hides a crouched player (1.2 m) only partly, a good size to tune.
func _build_low_cover() -> void:
	_add_box("LowCover1", Vector3(-7.0, 0.5, 12.0), Vector3(3.0, 1.0, 0.6), LOW_COVER_COLOR)
	_add_box("LowCover2", Vector3(-1.0, 0.5, 12.0), Vector3(2.0, 1.0, 0.6), LOW_COVER_COLOR)
	_add_box("LowCover3", Vector3(5.0, 0.5, 12.0), Vector3(4.0, 1.0, 0.6), LOW_COVER_COLOR)
	_add_box("LowCover4", Vector3(0.0, 0.5, 5.0), Vector3(0.6, 1.0, 5.0), LOW_COVER_COLOR)


func _build_high_cover() -> void:
	_add_box("HighWall1", Vector3(-10.0, 1.1, 0.0), Vector3(5.0, 2.2, 0.5), HIGH_COVER_COLOR)
	_add_box("HighWall2", Vector3(6.0, 1.1, 0.0), Vector3(7.0, 2.2, 0.5), HIGH_COVER_COLOR)
	_add_box("HighWall3", Vector3(-4.0, 1.1, -12.0), Vector3(0.5, 2.2, 6.0), HIGH_COVER_COLOR)


## Two pillars and a beam 1.4 m above the ground: a standing player (1.8 m) cannot pass
## underneath, a crouched one (1.2 m) can. Walk through along the Z axis.
func _build_low_beam() -> void:
	var x := -20.0
	_add_box("BeamPillarA", Vector3(x - 1.75, 0.95, -5.0), Vector3(0.5, 1.9, 0.5), BEAM_COLOR)
	_add_box("BeamPillarB", Vector3(x + 1.75, 0.95, -5.0), Vector3(0.5, 1.9, 0.5), BEAM_COLOR)
	_add_box("Beam", Vector3(x, 1.6, -5.0), Vector3(4.0, 0.4, 1.5), BEAM_COLOR)


## A 15 degree ramp (8 m long) climbing northwards to a raised platform.
func _build_ramp_and_platform() -> void:
	var angle := deg_to_rad(15.0)
	var length := 8.0
	var thickness := 0.4
	var rise := length * sin(angle)
	var run := length * cos(angle)
	var start_z := -2.0
	var x := 16.0
	# The slab's top surface must pass through (start_z, 0) and (start_z - run, rise).
	var center := Vector3(
		x,
		rise * 0.5 - thickness * 0.5 / cos(angle),
		start_z - run * 0.5 - thickness * 0.5 * sin(angle)
	)
	_add_box(
		"Ramp",
		center,
		Vector3(4.0, thickness, length),
		RAMP_COLOR,
		Vector3(rad_to_deg(angle), 0, 0)
	)
	_add_box(
		"Platform",
		Vector3(x, rise - thickness * 0.5, start_z - run - 4.0),
		Vector3(4.0, thickness, 8.0),
		RAMP_COLOR
	)


func _build_crates() -> void:
	_add_box("Crate1", Vector3(10.0, 0.5, 18.0), Vector3(1.0, 1.0, 1.0), CRATE_COLOR)
	_add_box("Crate2", Vector3(11.2, 0.5, 18.0), Vector3(1.0, 1.0, 1.0), CRATE_COLOR)
	_add_box("Crate3", Vector3(10.6, 1.5, 18.0), Vector3(1.0, 1.0, 1.0), CRATE_COLOR)
	_add_box("Crate4", Vector3(-14.0, 0.75, 20.0), Vector3(1.5, 1.5, 1.5), CRATE_COLOR)
	_add_box("Crate5", Vector3(-3.0, 0.5, -22.0), Vector3(2.0, 1.0, 1.0), CRATE_COLOR)
	_add_box("Crate6", Vector3(8.0, 0.5, -24.0), Vector3(1.0, 1.0, 2.0), CRATE_COLOR)


func _add_box(
	box_name: String, center: Vector3, size: Vector3, color: Color, tilt_degrees := Vector3.ZERO
) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.collision_layer = PhysicsLayers.WORLD
	body.collision_mask = 0
	body.position = center
	body.rotation_degrees = tilt_degrees

	var box_shape := BoxShape3D.new()
	box_shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = box_shape
	body.add_child(collision)

	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = _material_for(color)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = box_mesh
	body.add_child(mesh_instance)

	add_child(body)


func _material_for(color: Color) -> StandardMaterial3D:
	if _materials.has(color):
		return _materials[color] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.albedo_texture = _grid_texture
	# World-space triplanar mapping keeps the grid size identical on every box, whatever its scale:
	# that is what makes distances and speeds readable while playtesting.
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / _GRID_WORLD_METERS
	_materials[color] = material
	return material


func _make_grid_texture() -> ImageTexture:
	var image := Image.create_empty(
		_GRID_TEXTURE_SIZE, _GRID_TEXTURE_SIZE, false, Image.FORMAT_RGBA8
	)
	image.fill(Color.WHITE)
	var line_color := Color(0.7, 0.7, 0.7)
	for i in _GRID_TEXTURE_SIZE:
		for t in _GRID_LINE_PIXELS:
			image.set_pixel(i, t, line_color)
			image.set_pixel(t, i, line_color)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
