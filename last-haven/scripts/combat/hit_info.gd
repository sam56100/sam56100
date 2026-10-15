class_name HitInfo
extends RefCounted
## What a confirmed bullet hit did to a target (used for hit markers and damage numbers).

var damage: int = 0
var zone: DamageZone.Kind = DamageZone.Kind.TORSO
var killed: bool = false
var position: Vector3 = Vector3.ZERO
var target: Node = null
