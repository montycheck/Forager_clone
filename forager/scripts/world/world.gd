extends Node2D

@onready var world_generator: WorldGenerator = $WorldGenerator
@onready var player: Node2D = $YSortRoot/Player
@onready var resource_spawner = $YSortRoot/ResourceSpawner
@onready var structure_spawner = $YSortRoot/StructureSpawner

var loading: LoadingScreen

func _ready() -> void:
	loading = LoadingScreen.new()
	$UILayer.add_child(loading)   # ajouté en dernier = au-dessus de tout
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	await get_tree().process_frame   # laisse l'écran s'afficher

	if SaveManager.pending_load:
		await _load_existing_world()
	else:
		await _generate_new_world()

	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	loading.finish()

func _range(from: float, to: float, text: String) -> Callable:
	return func(p: float): loading.set_progress(lerpf(from, to, p), text)

func _load_existing_world() -> void:
	SaveManager.pending_load = false
	loading.set_progress(0.0, "Lecture de la sauvegarde...")
	world_generator.biome_map.setup(SaveManager.get_save_seed())
	await world_generator.generate(_range(0.05, 0.35, "Génération du terrain..."))
	await resource_spawner.generate_resources(_range(0.35, 0.9, "Placement des ressources..."))
	loading.set_progress(0.9, "Chargement de la partie...")
	await get_tree().process_frame
	SaveManager.load_game()

func _generate_new_world() -> void:
	var seed_to_use := SaveManager.current_seed
	loading.set_progress(0.0, "Recherche d'un monde...")
	world_generator.biome_map.setup(seed_to_use)

	var attempts := 0
	while (not world_generator.biome_map.has_all_biomes_represented() \
			or world_generator.biome_map.get_land_ratio() < 0.7) \
			and attempts < 20:
		seed_to_use += 1
		world_generator.biome_map.setup(seed_to_use)
		attempts += 1
		loading.set_progress(0.2 * attempts / 20.0)
		await get_tree().process_frame

	SaveManager.current_seed = seed_to_use
	await world_generator.generate(_range(0.2, 0.4, "Génération du terrain..."))
	loading.set_progress(0.4, "Placement des structures...")
	structure_spawner.spawn_requesters()
	await resource_spawner.generate_resources(_range(0.45, 1.0, "Placement des ressources..."))
	center_player_on_world()

func center_player_on_world() -> void:
	var tile_size := 32
	var center_x := (world_generator.biome_map.world_width * tile_size) / 2.0
	var center_y := (world_generator.biome_map.world_height * tile_size) / 2.0
	player.global_position = Vector2(center_x, center_y)
