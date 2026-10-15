class_name ShotResult
extends RefCounted
## What a single shot did, as traced from the muzzle.

var muzzle: Vector3 = Vector3.ZERO
## Where the bullet stopped (the impact point, or the end of its range if it hit nothing).
var end: Vector3 = Vector3.ZERO
var hit: bool = false
var normal: Vector3 = Vector3.UP
var collider: Object = null
var distance: float = 0.0
