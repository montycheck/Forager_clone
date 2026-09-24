extends Node2D

@onready var world_generator: WorldGenerator = $WorldGenerator
@onready var player: Node2D = $YSortRoot/Player
@onready var resource_spawner = $YSortRoot/ResourceSpawner

func _ready() -> void:
	if SaveManager.pending_load:
		SaveManager.pending_load = false
		world_generator.biome_map.setup(SaveManager.get_save_seed())
		world_generator.generate()
		resource_spawner.generate_resources()
		SaveManager.load_game()
	else:
		world_generator.biome_map.setup(SaveManager.current_seed)
		world_generator.generate()
		resource_spawner.generate_resources()
		center_player_on_world()

func center_player_on_world() -> void:
	var tile_size := 32
	var center_x := (world_generator.biome_map.world_width * tile_size) / 2.0
	var center_y := (world_generator.biome_map.world_height * tile_size) / 2.0
	player.global_position = Vector2(center_x, center_y)
