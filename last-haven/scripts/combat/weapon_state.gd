class_name WeaponState
extends RefCounted
## Pure weapon logic: ammo, fire rate, reload and spread. No nodes, no physics, no input.
##
## Time only advances through [method tick], so it is deterministic and unit-testable, and can run
## unchanged on a server. Reload and fire timings are timers, never animation lengths.

signal reload_started
signal reload_finished

enum Status { READY, RELOADING }

var data: WeaponData
var magazine: int
var reserve: int
var status: Status = Status.READY
## Inaccuracy added by recent shots, in degrees.
var extra_spread: float = 0.0

var _cooldown: float = 0.0
var _reload_left: float = 0.0


func _init(weapon_data: WeaponData) -> void:
	data = weapon_data
	magazine = data.magazine_size
	reserve = data.reserve_ammo


func tick(delta: float) -> void:
	# The cooldown may go slightly negative (at most one tick) so the average fire rate stays
	# exact even when the interval is not a multiple of the physics tick.
	_cooldown = maxf(_cooldown - delta, -delta)
	extra_spread = maxf(extra_spread - data.spread_recovery_per_second * delta, 0.0)
	if status == Status.RELOADING:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()


func can_fire() -> bool:
	return status == Status.READY and magazine > 0 and _cooldown <= 0.0


## Consumes one round if the weapon can fire. Returns true when a shot was fired.
func try_fire() -> bool:
	if not can_fire():
		return false
	magazine -= 1
	_cooldown += data.fire_interval()
	extra_spread = minf(extra_spread + data.spread_gain_per_shot, data.spread_max_extra)
	return true


## Starts a reload. Returns false if there is nothing to do (full magazine, no reserve, busy).
func start_reload() -> bool:
	if status == Status.RELOADING or magazine >= data.magazine_size or reserve <= 0:
		return false
	status = Status.RELOADING
	_reload_left = data.reload_seconds
	reload_started.emit()
	return true


func cancel_reload() -> void:
	status = Status.READY
	_reload_left = 0.0


func is_empty() -> bool:
	return magazine <= 0


## Half-angle of the firing cone in degrees, for the current aim state.
func current_spread(aiming: bool) -> float:
	return (data.spread_aim if aiming else data.spread_hip) + extra_spread


## 0..1 progress of the running reload, 0 when not reloading.
func reload_progress() -> float:
	if status != Status.RELOADING:
		return 0.0
	return clampf(1.0 - _reload_left / data.reload_seconds, 0.0, 1.0)


func _finish_reload() -> void:
	var taken := mini(data.magazine_size - magazine, reserve)
	magazine += taken
	reserve -= taken
	status = Status.READY
	_reload_left = 0.0
	reload_finished.emit()
