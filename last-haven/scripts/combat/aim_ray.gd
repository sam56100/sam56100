class_name AimRay
extends RefCounted
## Where the player is aiming: an origin and a normalised direction in world space.

var origin: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.FORWARD


static func create(ray_origin: Vector3, ray_direction: Vector3) -> AimRay:
	var ray := AimRay.new()
	ray.origin = ray_origin
	ray.direction = ray_direction.normalized()
	return ray
