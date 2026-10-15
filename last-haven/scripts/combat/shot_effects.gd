class_name ShotEffects
extends RefCounted
## Purely cosmetic shot feedback: a short tracer line and an impact flash. Never affects gameplay.

const TRACER_SECONDS := 0.06
const IMPACT_SECONDS := 0.15
const TRACER_COLOR := Color(1.0, 0.85, 0.5)
const IMPACT_COLOR := Color(1.0, 0.7, 0.3)

const _TRACER_THICKNESS := 0.025
const _TRACER_MIN_LENGTH := 0.1
const _IMPACT_RADIUS := 0.08


static func spawn(parent: Node, result: ShotResult) -> void:
	_spawn_tracer(parent, result.muzzle, result.end)
	if result.hit:
		_spawn_impact(parent, result.end)


static func _spawn_tracer(parent: Node, from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < _TRACER_MIN_LENGTH:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(_TRACER_THICKNESS, _TRACER_THICKNESS, length)
	mesh.material = _unshaded(TRACER_COLOR)
	var tracer := MeshInstance3D.new()
	tracer.name = "ShotTracer"
	tracer.mesh = mesh
	tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(tracer)
	tracer.global_position = (from + to) * 0.5
	var direction := (to - from).normalized()
	var up := Vector3.UP if absf(direction.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	tracer.look_at(to, up)
	parent.get_tree().create_timer(TRACER_SECONDS).timeout.connect(tracer.queue_free)


static func _spawn_impact(parent: Node, at: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = _IMPACT_RADIUS
	mesh.height = _IMPACT_RADIUS * 2.0
	mesh.material = _unshaded(IMPACT_COLOR)
	var flash := MeshInstance3D.new()
	flash.name = "ShotImpact"
	flash.mesh = mesh
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(flash)
	flash.global_position = at
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3.ZERO, IMPACT_SECONDS)
	tween.tween_callback(flash.queue_free)


static func _unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material
