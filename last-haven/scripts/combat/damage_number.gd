class_name DamageNumber
extends RefCounted
## Floating damage figure shown where a bullet landed. Cosmetic only.

const LIFETIME := 0.8
const RISE := 0.7
const NORMAL_COLOR := Color(1.0, 1.0, 1.0)
const HEADSHOT_COLOR := Color(1.0, 0.8, 0.2)
const KILL_COLOR := Color(1.0, 0.3, 0.25)


static func spawn(parent: Node, info: HitInfo) -> void:
	var label := Label3D.new()
	label.name = "DamageNumber"
	label.text = str(info.damage)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0009
	label.font_size = 36
	label.outline_size = 10
	label.modulate = _color_for(info)
	parent.add_child(label)
	label.global_position = info.position
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", info.position.y + RISE, LIFETIME)
	tween.tween_property(label, "modulate:a", 0.0, LIFETIME)
	tween.chain().tween_callback(label.queue_free)


static func _color_for(info: HitInfo) -> Color:
	if info.killed:
		return KILL_COLOR
	if info.zone == DamageZone.Kind.HEAD:
		return HEADSHOT_COLOR
	return NORMAL_COLOR
