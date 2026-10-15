class_name ActionInterrupts
extends RefCounted
## What breaks a timed action in progress (crafting, healing): fighting or moving fast.


static func breaks(frame: InputFrame) -> bool:
	var sprinting := frame.sprint and frame.move.y > 0.1
	return frame.fire_pressed or frame.jump_pressed or sprinting
