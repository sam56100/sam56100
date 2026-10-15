class_name DebugOverlay
extends CanvasLayer
## Developer overlay (F3 to toggle): the numbers to paste when reporting a playtest.

var target: PlayerController

var _label: Label


func _ready() -> void:
	layer = 100
	_label = Label.new()
	_label.position = Vector2(12.0, 8.0)
	var settings := LabelSettings.new()
	settings.font_size = 16
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	_label.label_settings = settings
	add_child(_label)


func _process(_delta: float) -> void:
	if not visible or target == null:
		return
	var version := Engine.get_version_info()
	_label.text = (
		"LAST HAVEN debug (F3)  |  Godot %s.%s.%s\n" % [version.major, version.minor, version.patch]
		+ "FPS: %d\n" % Engine.get_frames_per_second()
		+ "Speed: %.2f m/s\n" % target.horizontal_speed()
		+ "Stance: %s\n" % PlayerController.Stance.keys()[target.stance]
		+ "On floor: %s\n" % target.is_on_floor()
		+ "Position: %s" % str(target.global_position.snappedf(0.01))
	)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_F3:
			visible = not visible
