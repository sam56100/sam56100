class_name TrainingDummy
extends Node3D
## Shootable human-shaped target: head / torso / limbs hit zones, a health readout above it,
## and automatic respawn after being "killed". Built from code like the rest of the arena.

const _FALL_SECONDS := 0.35
const _FLASH_SECONDS := 0.12
const _HEAD_COLOR := Color(0.85, 0.3, 0.25)
const _TORSO_COLOR := Color(0.45, 0.55, 0.7)
const _LIMBS_COLOR := Color(0.6, 0.65, 0.72)
const _FLASH_COLOR := Color(1.0, 1.0, 1.0)

@export var max_health: int = 100
@export var respawn_seconds: float = 3.0

var health: HealthComponent

var _visuals: Node3D
var _zones: Array[HitZone] = []
var _materials: Array[StandardMaterial3D] = []
var _base_colors: Array[Color] = []
var _label: Label3D
var _fall_tween: Tween


func _ready() -> void:
	health = HealthComponent.new()
	health.name = "Health"
	health.max_health = max_health
	add_child(health)

	_visuals = Node3D.new()
	_visuals.name = "Visuals"
	add_child(_visuals)
	_build_body()
	_build_label()

	health.changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func is_dead() -> bool:
	return health.is_dead()


func _build_body() -> void:
	var head_shape := SphereShape3D.new()
	head_shape.radius = 0.15
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.14
	head_mesh.height = 0.28
	_add_zone(
		"Head", DamageZone.Kind.HEAD, head_shape, head_mesh, Vector3(0.0, 1.62, 0.0), _HEAD_COLOR
	)

	_add_box_zone(
		"Torso",
		DamageZone.Kind.TORSO,
		Vector3(0.5, 0.6, 0.3),
		Vector3(0.0, 1.15, 0.0),
		_TORSO_COLOR
	)
	_add_box_zone(
		"Legs",
		DamageZone.Kind.LIMBS,
		Vector3(0.42, 0.85, 0.28),
		Vector3(0.0, 0.425, 0.0),
		_LIMBS_COLOR
	)
	_add_box_zone(
		"ArmLeft",
		DamageZone.Kind.LIMBS,
		Vector3(0.12, 0.55, 0.14),
		Vector3(-0.31, 1.15, 0.0),
		_LIMBS_COLOR
	)
	_add_box_zone(
		"ArmRight",
		DamageZone.Kind.LIMBS,
		Vector3(0.12, 0.55, 0.14),
		Vector3(0.31, 1.15, 0.0),
		_LIMBS_COLOR
	)


func _add_box_zone(
	zone_name: String, kind: DamageZone.Kind, size: Vector3, center: Vector3, color: Color
) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_zone(zone_name, kind, shape, mesh, center, color)


func _add_zone(
	zone_name: String,
	kind: DamageZone.Kind,
	shape: Shape3D,
	mesh: PrimitiveMesh,
	center: Vector3,
	color: Color
) -> void:
	var zone := HitZone.new()
	zone.name = zone_name
	zone.zone = kind
	zone.multiplier = DamageZone.default_multiplier(kind)
	zone.health = health
	zone.position = center

	var collision := CollisionShape3D.new()
	collision.shape = shape
	zone.add_child(collision)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	zone.add_child(instance)

	_visuals.add_child(zone)
	_zones.append(zone)
	_materials.append(material)
	_base_colors.append(color)


func _build_label() -> void:
	_label = Label3D.new()
	_label.name = "HealthLabel"
	_label.text = str(health.current_health)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0.0, 2.05, 0.0)
	_label.pixel_size = 0.004
	_label.font_size = 40
	_label.outline_size = 10
	add_child(_label)


func _on_health_changed(current: int, _maximum: int) -> void:
	_label.text = str(current)


func _on_damaged(_amount: int) -> void:
	for i in _materials.size():
		_materials[i].albedo_color = _FLASH_COLOR
		var tween := create_tween()
		tween.tween_property(_materials[i], "albedo_color", _base_colors[i], _FLASH_SECONDS)


func _on_died() -> void:
	for zone in _zones:
		zone.set_shootable(false)
	_fall_tween = create_tween()
	_fall_tween.tween_property(_visuals, "rotation:x", -PI / 2.0, _FALL_SECONDS)
	get_tree().create_timer(respawn_seconds).timeout.connect(_respawn)


func _respawn() -> void:
	if not is_inside_tree():
		return
	# Stop a fall animation that may still be running, or it would lay the dummy down again.
	if _fall_tween != null and _fall_tween.is_valid():
		_fall_tween.kill()
	health.reset()
	_visuals.rotation.x = 0.0
	for zone in _zones:
		zone.set_shootable(true)
