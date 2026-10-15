class_name HitZone
extends StaticBody3D
## One hit volume of a target (head, torso, limbs). Bullets collide with these on the hitbox
## layer; a hit is turned into damage here. Server-side hit detection will use the same simple
## volumes, never the animated skeleton (see docs/PLAN_INITIAL.md, section 8.1).

@export var zone: DamageZone.Kind = DamageZone.Kind.TORSO
@export var multiplier: float = 1.0

## Health pool this zone damages. Set by the owner of the zone (e.g. TrainingDummy).
var health: HealthComponent


func _init() -> void:
	collision_layer = PhysicsLayers.HITBOXES
	collision_mask = 0


## Applies a bullet hit. Returns null when there is nothing to hurt (no health, already dead).
func receive_hit(base_damage: float, hit_position: Vector3) -> HitInfo:
	if health == null or health.is_dead():
		return null
	var info := HitInfo.new()
	info.zone = zone
	info.position = hit_position
	info.target = health.get_parent()
	info.damage = DamageCalculator.compute(base_damage, multiplier)
	health.take_damage(info.damage)
	info.killed = health.is_dead()
	return info


## Enables or disables this zone for bullets (a dead target cannot be shot again).
func set_shootable(shootable: bool) -> void:
	collision_layer = PhysicsLayers.HITBOXES if shootable else 0
