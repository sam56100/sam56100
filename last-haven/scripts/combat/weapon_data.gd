class_name WeaponData
extends Resource
## Static description of a firearm. Edit the .tres files in data/weapons/ to rebalance.

## Also used as the translation key for the in-game name.
@export var display_name: String = "Assault rifle"
## Hold to keep firing (true) or one shot per click (false).
@export var automatic: bool = true

@export_group("Damage")
## Damage of a torso hit; the hit zone multiplies it (see HitZone).
@export var damage: float = 18.0
@export var range_meters: float = 120.0

@export_group("Rate of fire")
@export var rounds_per_minute: float = 500.0

@export_group("Ammo")
@export var magazine_size: int = 30
@export var reserve_ammo: int = 90
@export var reload_seconds: float = 2.1

@export_group("Accuracy (half-angle of the firing cone, degrees)")
@export var spread_hip: float = 2.5
@export var spread_aim: float = 0.6
## Extra spread added by each shot, up to spread_max_extra, then recovering over time.
@export var spread_gain_per_shot: float = 0.5
@export var spread_max_extra: float = 3.0
@export var spread_recovery_per_second: float = 3.0

@export_group("Recoil (camera kick per shot, degrees)")
@export var recoil_pitch: float = 0.9
## Random sideways kick between -recoil_yaw and +recoil_yaw.
@export var recoil_yaw: float = 0.3


## Seconds between two shots.
func fire_interval() -> float:
	return 60.0 / maxf(rounds_per_minute, 1.0)
