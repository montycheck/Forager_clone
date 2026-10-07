extends Node2D

@onready var world_generator: WorldGenerator = $WorldGenerator
@onready var player: Node2D = $YSortRoot/Player
@onready var resource_spawner = $YSortRoot/ResourceSpawner
@onready var structure_spawner = $YSortRoot/StructureSpawner

func _ready() -> void:
	if SaveManager.pending_load:
		SaveManager.pending_load = false
		world_generator.biome_map.setup(SaveManager.get_save_seed())
		world_generator.generate()
		resource_spawner.generate_resources()
		SaveManager.load_game()
	else:
		var seed_to_use := SaveManager.current_seed
		world_generator.biome_map.setup(seed_to_use)

		var attempts := 0
		while (not world_generator.biome_map.has_all_biomes_represented() \
				or world_generator.biome_map.get_land_ratio() < 0.7) \
				and attempts < 20:
			seed_to_use += 1
			world_generator.biome_map.setup(seed_to_use)
			attempts += 1

		SaveManager.current_seed = seed_to_use
		world_generator.generate()
		structure_spawner.spawn_requesters()
		resource_spawner.generate_resources()
		center_player_on_world()

func center_player_on_world() -> void:
	var tile_size := 32
	var center_x := (world_generator.biome_map.world_width * tile_size) / 2.0
	var center_y := (world_generator.biome_map.world_height * tile_size) / 2.0
	player.global_position = Vector2(center_x, center_y)
