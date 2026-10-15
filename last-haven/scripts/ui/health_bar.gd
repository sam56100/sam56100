class_name HealthBar
extends Control
## Horizontal health bar that turns from green to red as health drops.

const _BACKGROUND_COLOR := Color(0.0, 0.0, 0.0, 0.55)
const _BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const _HEALTHY_COLOR := Color(0.35, 0.8, 0.4)
const _CRITICAL_COLOR := Color(0.9, 0.25, 0.2)

var current: int = 100
var maximum: int = 100


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(260.0, 18.0)


func set_values(new_current: int, new_maximum: int) -> void:
	if new_current == current and new_maximum == maximum:
		return
	current = new_current
	maximum = new_maximum
	queue_redraw()


func ratio() -> float:
	return clampf(float(current) / float(maxi(maximum, 1)), 0.0, 1.0)


func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	draw_rect(full, _BACKGROUND_COLOR)
	var fill_color := _CRITICAL_COLOR.lerp(_HEALTHY_COLOR, ratio())
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio(), size.y)), fill_color)
	draw_rect(full, _BORDER_COLOR, false, 1.0)
