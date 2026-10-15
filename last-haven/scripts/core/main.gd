extends Node3D
## Entry point: builds the world, spawns the local player and the debug overlay.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")


func _ready() -> void:
	Localization.setup()
	InputActions.register()
	_add_environment()

	var map := GreyboxMap.new()
	map.name = "Map"
	add_child(map)

	var player := PLAYER_SCENE.instantiate() as PlayerController
	player.name = "Player"
	# Placed before entering the tree so the camera rig starts at the right spot.
	player.transform = map.get_spawn_transform()
	add_child(player)

	var hud := Hud.new()
	hud.name = "Hud"
	hud.target = player
	add_child(hud)

	var overlay := DebugOverlay.new()
	overlay.name = "DebugOverlay"
	overlay.target = player
	add_child(overlay)


func _add_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
