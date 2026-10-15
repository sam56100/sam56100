class_name WeaponController
extends Node
## Turns player intent into shots: owns the [WeaponState], traces hitscan bullets and reports them.
##
## A shot is traced in two steps, as in most third-person shooters: first a ray from the camera
## through the crosshair finds what the player is pointing at, then a second ray from the weapon's
## muzzle to that point decides what is really hit. That way the bullet cannot pass through a wall
## that the camera merely peeks over.

signal shot_fired(result: ShotResult)
## A bullet hurt something. Emitted after [signal shot_fired].
signal hit_confirmed(info: HitInfo)
## Camera kick requested by a shot (degrees up, degrees sideways).
signal recoil_kick(pitch_degrees: float, yaw_degrees: float)

const _HIT_MASK := PhysicsLayers.WORLD | PhysicsLayers.HITBOXES
## The muzzle ray stops this far past the aimed point so it registers the surface it points at.
const _MUZZLE_RAY_OVERSHOOT := 0.3

@export var data: WeaponData

## Returns an [AimRay] (the camera's) when called. Set by the player; tests can stub it.
var aim_ray_provider: Callable
var state: WeaponState
var muzzle: Marker3D
var rng := RandomNumberGenerator.new()

var _body: CollisionObject3D
var _fire_was_held: bool = false
var _aiming: bool = false


func _ready() -> void:
	if data == null:
		data = preload("res://data/weapons/assault_rifle.tres")
	state = WeaponState.new(data)
	rng.randomize()


## Binds the weapon to the body that carries it (excluded from its own rays) and its muzzle.
func setup(body: CollisionObject3D, muzzle_marker: Marker3D) -> void:
	_body = body
	muzzle = muzzle_marker


func tick(frame: InputFrame, delta: float) -> void:
	state.tick(delta)
	_aiming = frame.aim_pressed
	if frame.reload_pressed:
		state.start_reload()
	var fire_edge := frame.fire_pressed and not _fire_was_held
	_fire_was_held = frame.fire_pressed
	if not frame.fire_pressed:
		return
	if state.is_empty() and state.status == WeaponState.Status.READY:
		state.start_reload()
		return
	if not data.automatic and not fire_edge:
		return
	if state.try_fire():
		_fire()


## Current firing-cone half-angle in degrees (drives the crosshair).
func current_spread_degrees() -> float:
	return state.current_spread(_aiming)


func _fire() -> void:
	if not aim_ray_provider.is_valid():
		return
	var ray := aim_ray_provider.call() as AimRay
	if ray == null:
		return
	var direction := _apply_spread(ray.direction, state.current_spread(_aiming))
	var result := _trace(ray.origin, direction)
	recoil_kick.emit(data.recoil_pitch, rng.randf_range(-data.recoil_yaw, data.recoil_yaw))
	shot_fired.emit(result)
	_apply_damage(result)


## Damage is applied right here for now (single player). With the network phase this moves to the
## server, which will own every hit and only tell clients the outcome.
func _apply_damage(result: ShotResult) -> void:
	var zone := result.collider as HitZone
	if zone == null:
		return
	var info := zone.receive_hit(data.damage, result.end)
	if info != null:
		hit_confirmed.emit(info)


## Back to a full weapon (respawn).
func refill() -> void:
	state = WeaponState.new(data)


func _trace(camera_origin: Vector3, direction: Vector3) -> ShotResult:
	var space := _body.get_world_3d().direct_space_state
	var far_point := camera_origin + direction * data.range_meters
	var aimed := _raycast(space, camera_origin, far_point)
	var target := far_point if aimed.is_empty() else aimed["position"] as Vector3

	var from := muzzle.global_position
	var to_target := target - from
	var muzzle_direction := to_target.normalized() if to_target.length() > 0.01 else direction
	var reach := to_target.length() + _MUZZLE_RAY_OVERSHOOT
	var hit := _raycast(space, from, from + muzzle_direction * reach)

	var result := ShotResult.new()
	result.muzzle = from
	if hit.is_empty() or from.distance_to(hit["position"] as Vector3) > data.range_meters:
		result.end = from + muzzle_direction * minf(reach, data.range_meters)
		result.distance = from.distance_to(result.end)
		return result
	result.hit = true
	result.end = hit["position"] as Vector3
	result.normal = hit["normal"] as Vector3
	result.collider = hit["collider"] as Object
	result.distance = from.distance_to(result.end)
	return result


func _raycast(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, _HIT_MASK)
	query.exclude = [_body.get_rid()]
	return space.intersect_ray(query)


## Rotates a direction by a random angle inside a cone (uniform over the cone's disc).
func _apply_spread(direction: Vector3, spread_degrees: float) -> Vector3:
	if spread_degrees <= 0.0:
		return direction
	var reference_up := Vector3.UP if absf(direction.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right := direction.cross(reference_up).normalized()
	var up := right.cross(direction).normalized()
	var angle := deg_to_rad(spread_degrees) * sqrt(rng.randf())
	var around := rng.randf() * TAU
	var offset := (right * cos(around) + up * sin(around)) * tan(angle)
	return (direction + offset).normalized()
