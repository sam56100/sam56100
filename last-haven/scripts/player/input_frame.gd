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
## Crafting menu key held.
var craft_menu_held: bool = false
## Recipe slot (1-5) pressed this tick while the menu is open; 0 = none.
var craft_select: int = 0
var use_heal_pressed: bool = false
## Debug builds only: hurts the player to test healing and death.
var debug_damage_pressed: bool = false
