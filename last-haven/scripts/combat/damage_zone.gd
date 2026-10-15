class_name DamageZone
extends RefCounted
## Body zones a bullet can hit, and how much each one multiplies the weapon's damage.

enum Kind { HEAD, TORSO, LIMBS }

const HEAD_MULTIPLIER := 2.0
const TORSO_MULTIPLIER := 1.0
const LIMBS_MULTIPLIER := 0.75


static func default_multiplier(kind: Kind) -> float:
	match kind:
		Kind.HEAD:
			return HEAD_MULTIPLIER
		Kind.LIMBS:
			return LIMBS_MULTIPLIER
		_:
			return TORSO_MULTIPLIER
