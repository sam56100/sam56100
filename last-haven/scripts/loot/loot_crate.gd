class_name LootCrate
extends Interactable
## A supply crate holding crafting components. Quick to open (hold E), refills after a while so
## the training arena stays usable; real refill rules come with the match mode (phase 3).

signal opened(loot: Dictionary)
signal refilled

const _BASE_SIZE := Vector3(0.9, 0.5, 0.6)
const _LID_SIZE := Vector3(0.94, 0.12, 0.64)
const _OPEN_ANGLE_DEGREES := 110.0
const _LID_SECONDS := 0.25
const _BASE_COLOR := Color(0.32, 0.36, 0.24)
const _LID_COLOR := Color(0.5, 0.55, 0.32)
const _MARKER_RANGE := 18.0

@export var loot_table: LootTable
@export var open_seconds: float = 0.8
@export var refill_seconds: float = 25.0

var is_open: bool = false
var rng := RandomNumberGenerator.new()

var _lid_pivot: Node3D
var _marker: Label3D


func _ready() -> void:
	super()
	collision_layer = PhysicsLayers.WORLD
	collision_mask = 0
	if loot_table == null:
		loot_table = preload("res://data/loot/crate_basic.tres")
	rng.randomize()
	_build()


func can_interact(_player: PlayerController) -> bool:
	return not is_open


func get_interaction_prompt() -> String:
	return "Hold [E] to open"


func get_interaction_duration() -> float:
	return open_seconds


func interact(player: PlayerController) -> void:
	if is_open:
		return
	is_open = true
	var loot := loot_table.roll(rng)
	player.collect_loot(loot)
	_show_open(true)
	opened.emit(loot)
	if refill_seconds > 0.0:
		get_tree().create_timer(refill_seconds).timeout.connect(_refill)


func _refill() -> void:
	if not is_inside_tree():
		return
	is_open = false
	_show_open(false)
	refilled.emit()


func _build() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(_BASE_SIZE.x, _BASE_SIZE.y + _LID_SIZE.y, _BASE_SIZE.z)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = shape.size.y * 0.5
	add_child(collision)

	add_child(_make_box("Base", _BASE_SIZE, Vector3(0.0, _BASE_SIZE.y * 0.5, 0.0), _BASE_COLOR))

	# The lid hinges on its back edge (-Z) and swings up when the crate is opened.
	_lid_pivot = Node3D.new()
	_lid_pivot.name = "LidPivot"
	_lid_pivot.position = Vector3(0.0, _BASE_SIZE.y, -_BASE_SIZE.z * 0.5)
	add_child(_lid_pivot)
	_lid_pivot.add_child(
		_make_box("Lid", _LID_SIZE, Vector3(0.0, _LID_SIZE.y * 0.5, _LID_SIZE.z * 0.5), _LID_COLOR)
	)

	_marker = Label3D.new()
	_marker.name = "Marker"
	_marker.text = tr("Crate")
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.fixed_size = true
	_marker.pixel_size = 0.0011
	_marker.font_size = 26
	_marker.outline_size = 8
	_marker.position = Vector3(0.0, 1.25, 0.0)
	_marker.visibility_range_end = _MARKER_RANGE
	add_child(_marker)


func _make_box(box_name: String, size: Vector3, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = box_name
	instance.mesh = mesh
	instance.position = center
	return instance


func _show_open(open: bool) -> void:
	_marker.visible = not open
	var angle := -deg_to_rad(_OPEN_ANGLE_DEGREES) if open else 0.0
	var tween := create_tween()
	tween.tween_property(_lid_pivot, "rotation:x", angle, _LID_SECONDS)
