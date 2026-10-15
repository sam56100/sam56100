extends TestCase
## Pure weapon logic: no physics, time only moves through tick().

const TICK := 1.0 / 60.0
const TORSO_MULTIPLIER := 1.0
const PLAYER_HEALTH := 100

var _data: WeaponData
var _state: WeaponState


func before_each() -> void:
	var base := preload("res://data/weapons/assault_rifle.tres") as WeaponData
	_data = base.duplicate() as WeaponData
	_state = WeaponState.new(_data)


func test_starts_with_a_full_magazine_and_its_reserve() -> void:
	assert_eq(_state.magazine, _data.magazine_size)
	assert_eq(_state.reserve, _data.reserve_ammo)
	assert_eq(_state.status, WeaponState.Status.READY)


func test_firing_consumes_one_round() -> void:
	assert_true(_state.try_fire())
	assert_eq(_state.magazine, _data.magazine_size - 1)


func test_cannot_fire_twice_in_the_same_tick() -> void:
	assert_true(_state.try_fire())
	assert_false(_state.try_fire())
	assert_eq(_state.magazine, _data.magazine_size - 1)


func test_fire_rate_matches_rounds_per_minute() -> void:
	var shots := 0
	var ticks := 120  # two seconds
	for i in ticks:
		_state.tick(TICK)
		if _state.try_fire():
			shots += 1
	var expected := ticks * TICK / _data.fire_interval() + 1.0
	assert_true(
		absf(shots - expected) <= 1.0, "expected about %.1f shots, got %d" % [expected, shots]
	)


func test_cannot_fire_with_an_empty_magazine() -> void:
	_state.magazine = 0
	_state.tick(TICK)
	assert_false(_state.try_fire())
	assert_true(_state.is_empty())


func test_reload_refills_the_magazine_from_the_reserve() -> void:
	_state.magazine = 10
	assert_true(_state.start_reload())
	assert_eq(_state.status, WeaponState.Status.RELOADING)
	_run(_data.reload_seconds + 0.05)
	assert_eq(_state.magazine, _data.magazine_size)
	assert_eq(_state.reserve, _data.reserve_ammo - (_data.magazine_size - 10))
	assert_eq(_state.status, WeaponState.Status.READY)


func test_reload_takes_only_what_is_left_in_the_reserve() -> void:
	_state.magazine = 10
	_state.reserve = 5
	_state.start_reload()
	_run(_data.reload_seconds + 0.05)
	assert_eq(_state.magazine, 15)
	assert_eq(_state.reserve, 0)


func test_no_reload_when_full_or_without_reserve() -> void:
	assert_false(_state.start_reload(), "full magazine")
	_state.magazine = 5
	_state.reserve = 0
	assert_false(_state.start_reload(), "no reserve")


func test_cannot_fire_while_reloading_but_can_afterwards() -> void:
	_state.magazine = 10
	_state.start_reload()
	_state.tick(TICK)
	assert_false(_state.try_fire())
	_run(_data.reload_seconds + 0.05)
	assert_true(_state.try_fire())


func test_cancelling_a_reload_keeps_the_ammo_untouched() -> void:
	_state.magazine = 10
	_state.start_reload()
	_run(_data.reload_seconds * 0.5)
	_state.cancel_reload()
	_run(_data.reload_seconds)
	assert_eq(_state.magazine, 10)
	assert_eq(_state.reserve, _data.reserve_ammo)
	assert_eq(_state.status, WeaponState.Status.READY)


func test_reload_progress_runs_from_zero_to_one() -> void:
	assert_almost_eq(_state.reload_progress(), 0.0, 0.0001)
	_state.magazine = 0
	_state.start_reload()
	_run(_data.reload_seconds * 0.5)
	assert_almost_eq(_state.reload_progress(), 0.5, 0.05)


func test_reload_signals_fire_once_each() -> void:
	var started := [0]
	var finished := [0]
	_state.reload_started.connect(func() -> void: started[0] += 1)
	_state.reload_finished.connect(func() -> void: finished[0] += 1)
	_state.magazine = 0
	_state.start_reload()
	_run(_data.reload_seconds + 0.05)
	assert_eq(started[0], 1)
	assert_eq(finished[0], 1)


func test_aiming_is_more_accurate_than_hip_fire() -> void:
	assert_true(_state.current_spread(true) < _state.current_spread(false))


func test_spread_grows_with_shots_is_capped_and_recovers() -> void:
	_data.rounds_per_minute = 60000.0  # one shot per tick
	_state.magazine = 200
	var base := _state.current_spread(false)
	for i in 3:
		_state.tick(TICK)
		_state.try_fire()
	assert_true(_state.current_spread(false) > base, "spread should grow while firing")
	for i in 100:
		_state.tick(TICK)
		_state.try_fire()
	assert_true(
		_state.current_spread(false) <= base + _data.spread_max_extra + 0.001, "spread is capped"
	)
	_run(5.0)
	assert_almost_eq(_state.current_spread(false), base, 0.001)


func test_time_to_kill_stays_in_the_design_band() -> void:
	# Design target: a full-health player dies in roughly 0.6 to 1.0 s of sustained torso fire,
	# long enough to react, short enough to feel lethal.
	var damage_per_hit := _data.damage * TORSO_MULTIPLIER
	var hits_to_kill := ceili(PLAYER_HEALTH / damage_per_hit)
	var time_to_kill := (hits_to_kill - 1) * _data.fire_interval()
	assert_true(
		time_to_kill >= 0.4 and time_to_kill <= 1.0,
		"time to kill %.2fs (%d hits) is outside the 0.4-1.0s band" % [time_to_kill, hits_to_kill]
	)


func _run(seconds: float) -> void:
	for i in ceili(seconds / TICK):
		_state.tick(TICK)
