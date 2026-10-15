class_name ActionBar
extends Control
## Thin progress bar for timed actions (opening a crate, crafting, healing).

const _BACKGROUND_COLOR := Color(0.0, 0.0, 0.0, 0.55)
const _FILL_COLOR := Color(0.95, 0.6, 0.2)

var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _BACKGROUND_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * progress, size.y)), _FILL_COLOR)
