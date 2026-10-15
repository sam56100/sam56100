class_name MovementConfig
extends Resource
## Tunable locomotion parameters.
##
## Kept as a Resource so balancing never needs a code change: edit
## data/player/movement_default.tres in the Godot inspector.

@export_group("Speeds (m/s)")
@export var walk_speed: float = 3.6
@export var sprint_speed: float = 6.2
@export var crouch_speed: float = 2.0

@export_group("Acceleration (m/s²)")
@export var ground_acceleration: float = 22.0
@export var ground_deceleration: float = 18.0
@export var air_acceleration: float = 4.0

@export_group("Vertical")
## Initial upward speed of a jump.
@export var jump_velocity: float = 4.6
## Heavier than real life (9.8) on purpose: snappier, "weightier" jumps.
@export var gravity: float = 16.0
@export var max_fall_speed: float = 40.0

@export_group("Body")
@export var stand_height: float = 1.8
@export var crouch_height: float = 1.2
@export var radius: float = 0.35
## How fast the body turns toward its movement direction (higher = snappier).
@export var turn_rate: float = 12.0
