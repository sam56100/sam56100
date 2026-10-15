extends TestCase
## HUD text and crosshair, driven by a real player. Also checks the French translation.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")

var _world: Node3D
var _player: PlayerController
var _hud: Hud
var _frame: InputFrame


func before_each() -> void:
	Localization.setup()
	_world = Node3D.new()
	tree.root.add_child(_world)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = PhysicsLayers.WORLD
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_world.add_child(floor_body)
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_world.add_child(_player)
	_frame = InputFrame.new()
	_player.input_override = _frame
	_hud = Hud.new()
	_hud.target = _player
	_world.add_child(_hud)
	await _frames(5)


func after_each() -> void:
	_world.queue_free()
	await tree.process_frame


func test_french_translations_are_registered() -> void:
	assert_eq(str(TranslationServer.translate("Reloading")), "Rechargement")
	assert_eq(str(TranslationServer.translate("Assault rifle")), "Fusil d'assaut")


func test_ammo_counter_shows_magazine_and_reserve() -> void:
	_hud.refresh()
	var data := _player.weapon.data
	assert_eq(_hud.get_ammo_text(), "%d / %d" % [data.magazine_size, data.reserve_ammo])


func test_ammo_counter_goes_down_when_firing() -> void:
	var data := _player.weapon.data
	_frame.fire_pressed = true
	await _frames(1)
	_frame.fire_pressed = false
	await _frames(2)
	_hud.refresh()
	assert_eq(_hud.get_ammo_text(), "%d / %d" % [data.magazine_size - 1, data.reserve_ammo])


func test_weapon_name_is_shown_in_french() -> void:
	_hud.refresh()
	assert_eq(_hud.get_status_text(), "Fusil d'assaut")


func test_reloading_is_announced_in_french_with_progress() -> void:
	_player.weapon.state.magazine = 0
	_player.weapon.state.start_reload()
	await _frames(30)
	_hud.refresh()
	assert_true(_hud.get_status_text().begins_with("Rechargement"), _hud.get_status_text())
	assert_true(_hud.get_status_text().ends_with("%"))


func test_empty_weapon_without_reserve_says_empty() -> void:
	_player.weapon.state.magazine = 0
	_player.weapon.state.reserve = 0
	_hud.refresh()
	assert_eq(_hud.get_status_text(), "Vide")


func test_crosshair_opens_up_while_firing_and_tightens_when_aiming() -> void:
	_hud.refresh()
	var resting := _hud.get_crosshair().spread_pixels
	assert_true(resting > 0.0)
	_frame.aim_pressed = true
	await _frames(40)
	_hud.refresh()
	var aiming := _hud.get_crosshair().spread_pixels
	assert_true(
		aiming < resting, "aiming %.1f px should be tighter than hip %.1f px" % [aiming, resting]
	)


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
