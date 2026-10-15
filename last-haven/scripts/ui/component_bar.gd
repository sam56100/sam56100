class_name ComponentBar
extends HBoxContainer
## The six crafting components with how many the player carries. Empty ones are dimmed.

const _SWATCH_SIZE := 30.0
const _EMPTY_ALPHA := 0.35

var _swatches: Dictionary = {}
var _counts: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 12)
	for type in CraftComponent.all():
		add_child(_make_slot(type))


## Updates every count from the inventory.
func refresh(inventory: ComponentInventory) -> void:
	for type in CraftComponent.all():
		var amount := inventory.count(type)
		(_counts[type] as Label).text = str(amount)
		(_swatches[type] as Control).modulate.a = 1.0 if amount > 0 else _EMPTY_ALPHA


func get_count_text(type: CraftComponent.Type) -> String:
	return (_counts[type] as Label).text


func _make_slot(type: CraftComponent.Type) -> Control:
	var slot := VBoxContainer.new()
	slot.name = CraftComponent.key(type)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_constant_override("separation", 0)

	var swatch := ColorRect.new()
	swatch.color = CraftComponent.color(type)
	swatch.custom_minimum_size = Vector2(_SWATCH_SIZE, _SWATCH_SIZE)
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(swatch)
	_swatches[type] = swatch

	var count := _make_label("0", 20)
	slot.add_child(count)
	_counts[type] = count

	slot.add_child(_make_label(CraftComponent.display_name(type), 12))
	return slot


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.outline_size = 4
	settings.outline_color = Color(0.0, 0.0, 0.0, 0.85)
	label.label_settings = settings
	return label
