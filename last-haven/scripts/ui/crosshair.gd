class_name Crosshair
extends Control
## Dynamic crosshair: four ticks around the screen centre that move apart with weapon
## inaccuracy, plus a hit marker (white on a hit, red on a kill).

const _TICK_LENGTH := 9.0
const _TICK_WIDTH := 2.0
const _BASE_GAP := 5.0
const _OUTLINE_EXTRA := 2.0
const _HIT_MARKER_SECONDS := 0.14
const _HIT_MARKER_SIZE := 7.0
const _TICK_COLOR := Color(1.0, 1.0, 1.0, 0.92)
const _OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.55)
const _HIT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const _KILL_COLOR := Color(1.0, 0.25, 0.2, 1.0)

## Extra gap in pixels, set by the HUD from the current weapon spread.
var spread_pixels: float = 0.0:
	set(value):
		spread_pixels = value
		queue_redraw()

var _hit_time_left: float = 0.0
var _hit_color: Color = _HIT_COLOR


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if _hit_time_left > 0.0:
		_hit_time_left = maxf(_hit_time_left - delta, 0.0)
		queue_redraw()


## Flashes the hit marker. Red when the shot killed the target.
func show_hit(killed: bool) -> void:
	_hit_color = _KILL_COLOR if killed else _HIT_COLOR
	_hit_time_left = _HIT_MARKER_SECONDS
	queue_redraw()


func is_hit_marker_visible() -> bool:
	return _hit_time_left > 0.0


func _draw() -> void:
	var center := size * 0.5
	var gap := _BASE_GAP + spread_pixels
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var start := center + direction * gap
		var end := center + direction * (gap + _TICK_LENGTH)
		draw_line(start, end, _OUTLINE_COLOR, _TICK_WIDTH + _OUTLINE_EXTRA)
		draw_line(start, end, _TICK_COLOR, _TICK_WIDTH)
	if _hit_time_left > 0.0:
		for diagonal: Vector2 in [Vector2(1, 1), Vector2(1, -1)]:
			var offset := diagonal.normalized() * _HIT_MARKER_SIZE
			draw_line(center - offset * 2.0, center - offset, _hit_color, _TICK_WIDTH + 1.0)
			draw_line(center + offset, center + offset * 2.0, _hit_color, _TICK_WIDTH + 1.0)
