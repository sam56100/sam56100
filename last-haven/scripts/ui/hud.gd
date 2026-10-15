class_name Hud
extends CanvasLayer
## In-game HUD. Dumb on purpose: it only reads the player's state and never changes gameplay.

const _MARGIN := 24.0
const _TEXT_COLOR := Color(1.0, 1.0, 1.0)
const _WARNING_COLOR := Color(1.0, 0.35, 0.3)

var target: PlayerController

var _crosshair: Crosshair
var _ammo_label: Label
var _status_label: Label


func _ready() -> void:
	layer = 10
	_crosshair = Crosshair.new()
	_crosshair.name = "Crosshair"
	add_child(_crosshair)

	_ammo_label = _make_label("AmmoLabel", 34, Control.PRESET_BOTTOM_RIGHT)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ammo_label.offset_left = -300.0
	_ammo_label.offset_right = -_MARGIN
	_ammo_label.offset_top = -80.0
	_ammo_label.offset_bottom = -_MARGIN

	_status_label = _make_label("StatusLabel", 18, Control.PRESET_BOTTOM_RIGHT)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.offset_left = -300.0
	_status_label.offset_right = -_MARGIN
	_status_label.offset_top = -108.0
	_status_label.offset_bottom = -84.0


func _process(_delta: float) -> void:
	refresh()


## Updates every element from the player's current state.
func refresh() -> void:
	if target == null:
		return
	var state := target.weapon.state
	_ammo_label.text = "%d / %d" % [state.magazine, state.reserve]
	_ammo_label.add_theme_color_override(
		"font_color", _WARNING_COLOR if state.magazine == 0 else _TEXT_COLOR
	)
	if state.status == WeaponState.Status.RELOADING:
		_status_label.text = "%s %d%%" % [tr("Reloading"), roundi(state.reload_progress() * 100.0)]
	elif state.magazine == 0 and state.reserve == 0:
		_status_label.text = tr("Empty")
	else:
		_status_label.text = tr(target.weapon.data.display_name)
	_crosshair.spread_pixels = _spread_to_pixels(target.weapon.current_spread_degrees())


func get_crosshair() -> Crosshair:
	return _crosshair


func get_ammo_text() -> String:
	return _ammo_label.text


func get_status_text() -> String:
	return _status_label.text


## Converts a cone half-angle into on-screen pixels for the current camera zoom.
func _spread_to_pixels(spread_degrees: float) -> float:
	var camera := target.get_camera()
	if camera == null:
		return 0.0
	var half_height := get_viewport().get_visible_rect().size.y * 0.5
	var half_fov := tan(deg_to_rad(camera.fov) * 0.5)
	return tan(deg_to_rad(spread_degrees)) / half_fov * half_height


func _make_label(label_name: String, font_size: int, preset: Control.LayoutPreset) -> Label:
	var label := Label.new()
	label.name = label_name
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = _TEXT_COLOR
	settings.outline_size = 5
	settings.outline_color = Color(0.0, 0.0, 0.0, 0.85)
	label.label_settings = settings
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.set_anchors_and_offsets_preset(preset)
	return label
