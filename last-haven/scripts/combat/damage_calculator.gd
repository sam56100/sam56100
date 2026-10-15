class_name DamageCalculator
extends RefCounted
## The single place that turns a weapon's damage and a hit zone into integer damage.


## Rounded damage of one hit; a hit always deals at least 1.
static func compute(base_damage: float, multiplier: float) -> int:
	return maxi(1, roundi(base_damage * multiplier))


## How many hits of the given size it takes to bring `health` down to zero.
static func hits_to_kill(health: int, damage_per_hit: int) -> int:
	return ceili(float(health) / float(maxi(damage_per_hit, 1)))
