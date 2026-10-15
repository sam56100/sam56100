class_name Hud
extends CanvasLayer
## In-game HUD. Dumb on purpose: it only reads the player's state and never changes gameplay.

const _MARGIN := 24.0
const _TEXT_COLOR := Color(1.0, 1.0, 1.0)
const _WARNING_COLOR := Color(1.0, 0.35, 0.3)
const _TOAST_SECONDS := 2.5

var target: PlayerController

var _crosshair: Crosshair
var _ammo_label: Label
var _status_label: Label
var _health_bar: HealthBar
var _health_label: Label
var _center_label: Label
var _component_bar: ComponentBar
var _prompt_label: Label
var _action_label: Label
var _action_bar: ActionBar
var _toast_label: Label
var _craft_panel: CraftPanel
var _items_label: Label
var _craft_hint_label: Label
var _toast_time_left: float = 0.0


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

	_component_bar = ComponentBar.new()
	_component_bar.name = "ComponentBar"
	add_child(_component_bar)
	_component_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_place(_component_bar, -200.0, 200.0, -96.0, -_MARGIN)

	_prompt_label = _make_label("PromptLabel", 22, Control.PRESET_CENTER)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_prompt_label, -300.0, 300.0, 90.0, 124.0)

	_action_label = _make_label("ActionLabel", 18, Control.PRESET_CENTER)
	_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_action_label, -300.0, 300.0, 126.0, 152.0)

	_action_bar = ActionBar.new()
	_action_bar.name = "ActionBar"
	add_child(_action_bar)
	_action_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_place(_action_bar, -110.0, 110.0, 156.0, 164.0)

	_craft_panel = CraftPanel.new()
	_craft_panel.name = "CraftPanel"
	add_child(_craft_panel)
	_craft_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_place(_craft_panel, -260.0, 260.0, -190.0, -104.0)

	_craft_hint_label = _make_label("CraftHintLabel", 14, Control.PRESET_CENTER_BOTTOM)
	_craft_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_craft_hint_label, -200.0, 200.0, -122.0, -100.0)

	_items_label = _make_label("ItemsLabel", 20, Control.PRESET_BOTTOM_LEFT)
	_place(_items_label, _MARGIN, 300.0, -104.0, -76.0)

	_toast_label = _make_label("ToastLabel", 24, Control.PRESET_CENTER_TOP)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_toast_label, -300.0, 300.0, 70.0, 104.0)

	if target != null:
		target.weapon.hit_confirmed.connect(_on_hit_confirmed)
		target.loot_collected.connect(_on_loot_collected)


func _process(delta: float) -> void:
	refresh()
	_update_toast(delta)


## Updates every element from the player's current state.
func refresh() -> void:
	if target == null:
		return
	_refresh_weapon()
	_refresh_health()
	_refresh_interaction()
	_refresh_crafting()
	_component_bar.refresh(target.inventory)


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


func get_component_bar() -> ComponentBar:
	return _component_bar


func get_craft_panel() -> CraftPanel:
	return _craft_panel


func get_items_text() -> String:
	return _items_label.text


func get_prompt_text() -> String:
	return _prompt_label.text


func get_action_text() -> String:
	return _action_label.text


func get_action_progress() -> float:
	return _action_bar.progress


func get_toast_text() -> String:
	return _toast_label.text if _toast_label.visible else ""


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


func _refresh_interaction() -> void:
	var interactor := target.interactor
	var action_text := ""
	var progress := 0.0
	if target.crafter.is_crafting():
		action_text = "%s: %s" % [tr("Crafting"), tr(target.crafter.current_recipe.display_name)]
		progress = target.crafter.progress()
	elif target.item_user.is_using():
		action_text = tr("Healing")
		progress = target.item_user.progress()
	elif interactor.is_interacting():
		action_text = tr("Opening")
		progress = interactor.progress()
	_action_label.text = action_text
	_action_bar.progress = progress
	_action_bar.visible = action_text != ""
	var show_prompt := interactor.has_target() and action_text == ""
	_prompt_label.text = tr(interactor.get_prompt()) if show_prompt else ""


func _refresh_crafting() -> void:
	_craft_panel.refresh(target.crafter.recipes, target.inventory, target.crafter.menu_open)
	var kits := target.items.count(CraftedItem.Kind.HEAL_KIT)
	_items_label.text = "%s x%d  [H]" % [tr("Heal kit"), kits] if kits > 0 else ""
	_craft_hint_label.text = tr("Hold [Tab] to craft") if not target.crafter.menu_open else ""


func _on_loot_collected(loot: Dictionary) -> void:
	var parts: PackedStringArray = []
	for type: int in loot:
		parts.append(
			"+%d %s" % [loot[type], CraftComponent.display_name(type as CraftComponent.Type)]
		)
	_toast_label.text = "   ".join(parts)
	_toast_label.visible = true
	_toast_label.modulate.a = 1.0
	_toast_time_left = _TOAST_SECONDS


func _update_toast(delta: float) -> void:
	if _toast_time_left <= 0.0:
		_toast_label.visible = false
		return
	_toast_time_left -= delta
	_toast_label.modulate.a = clampf(_toast_time_left / 0.5, 0.0, 1.0)


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
