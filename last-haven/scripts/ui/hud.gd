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
var _health_bar: HealthBar
var _health_label: Label
var _center_label: Label


func _ready() -> void:
	layer = 10
	_crosshair = Crosshair.new()
	_crosshair.name = "Crosshair"
	add_child(_crosshair)

	_ammo_label = _make_label("AmmoLabel", 34, Control.PRESET_BOTTOM_RIGHT)
	_place(_ammo_label, -300.0, -_MARGIN, -80.0, -_MARGIN)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_status_label = _make_label("StatusLabel", 18, Control.PRESET_BOTTOM_RIGHT)
	_place(_status_label, -300.0, -_MARGIN, -108.0, -84.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_health_label = _make_label("HealthLabel", 22, Control.PRESET_BOTTOM_LEFT)
	_place(_health_label, _MARGIN, 300.0, -70.0, -_MARGIN - 22.0)

	_health_bar = HealthBar.new()
	_health_bar.name = "HealthBar"
	add_child(_health_bar)
	_health_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_place(_health_bar, _MARGIN, _MARGIN + 260.0, -_MARGIN - 18.0, -_MARGIN)

	_center_label = _make_label("CenterLabel", 40, Control.PRESET_CENTER)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_center_label, -300.0, 300.0, 70.0, 130.0)
	_center_label.visible = false

	if target != null:
		target.weapon.hit_confirmed.connect(_on_hit_confirmed)


func _process(_delta: float) -> void:
	refresh()


## Updates every element from the player's current state.
func refresh() -> void:
	if target == null:
		return
	_refresh_weapon()
	_refresh_health()


func get_crosshair() -> Crosshair:
	return _crosshair


func get_ammo_text() -> String:
	return _ammo_label.text


func get_status_text() -> String:
	return _status_label.text


func get_health_bar() -> HealthBar:
	return _health_bar


func get_health_text() -> String:
	return _health_label.text


func get_center_text() -> String:
	return _center_label.text if _center_label.visible else ""


func _refresh_weapon() -> void:
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


func _refresh_health() -> void:
	var health := target.health
	_health_bar.set_values(health.current_health, health.max_health)
	_health_label.text = str(health.current_health)
	_health_label.add_theme_color_override(
		"font_color", _WARNING_COLOR if health.health_ratio() <= 0.3 else _TEXT_COLOR
	)
	_center_label.visible = health.is_dead()
	if health.is_dead():
		_center_label.text = tr("Eliminated")


## Converts a cone half-angle into on-screen pixels for the current camera zoom.
func _spread_to_pixels(spread_degrees: float) -> float:
	var camera := target.get_camera()
	if camera == null:
		return 0.0
	var half_height := get_viewport().get_visible_rect().size.y * 0.5
	var half_fov := tan(deg_to_rad(camera.fov) * 0.5)
	return tan(deg_to_rad(spread_degrees)) / half_fov * half_height


func _on_hit_confirmed(info: HitInfo) -> void:
	_crosshair.show_hit(info.killed)


## Sets the four offsets of a control in one call (left, right, top, bottom).
func _place(control: Control, left: float, right: float, top: float, bottom: float) -> void:
	control.offset_left = left
	control.offset_right = right
	control.offset_top = top
	control.offset_bottom = bottom


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
