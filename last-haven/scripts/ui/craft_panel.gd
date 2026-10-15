class_name CraftPanel
extends VBoxContainer
## Compact crafting menu, shown while the craft key is held: one line per recipe with its slot
## number, its two components, and greyed out when the player cannot afford it.

const _UNAFFORDABLE_ALPHA := 0.45

var _header: Label
var _lines: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_header = _make_label(18)
	add_child(_header)


## Shows or hides the menu and refreshes every recipe line.
func refresh(recipes: Array[Recipe], inventory: ComponentInventory, open: bool) -> void:
	visible = open
	if not open:
		return
	_header.text = tr("Crafting")
	while _lines.size() < recipes.size():
		var line := _make_label(22)
		add_child(line)
		_lines.append(line)
	for i in recipes.size():
		var recipe := recipes[i]
		_lines[i].text = (
			"[%d] %s: %s + %s"
			% [
				i + 1,
				tr(recipe.display_name),
				CraftComponent.display_name(recipe.component_a),
				CraftComponent.display_name(recipe.component_b),
			]
		)
		var affordable := inventory.can_afford(recipe.cost())
		_lines[i].modulate.a = 1.0 if affordable else _UNAFFORDABLE_ALPHA


func get_line_text(index: int) -> String:
	return _lines[index].text


func is_line_dimmed(index: int) -> bool:
	return _lines[index].modulate.a < 1.0


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.outline_size = 5
	settings.outline_color = Color(0.0, 0.0, 0.0, 0.85)
	label.label_settings = settings
	return label
