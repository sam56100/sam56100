class_name InputFrame
extends RefCounted
## One tick of player intent.
##
## Pure data on purpose: the simulation only reads this, never the keyboard, so the same frame can
## later be sent to the server and replayed for client-side prediction.

## x = right, y = forward. Length <= 1.
var move: Vector2 = Vector2.ZERO
## Camera yaw in radians; movement is relative to it.
var aim_yaw: float = 0.0
var sprint: bool = false
var jump_pressed: bool = false
var crouch_toggle_pressed: bool = false
## Aim down sights (held).
var aim_pressed: bool = false
## Trigger held down.
var fire_pressed: bool = false
var reload_pressed: bool = false
## Interact key held (open crates, ...).
var interact_held: bool = false
## Debug builds only: hurts the player to test healing and death.
var debug_damage_pressed: bool = false
