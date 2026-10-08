extends Node
class_name WorldGenerator

@export var biome_map: BiomeMap
@export var ground_layer: TileMapLayer
@export var tileset_source_id: int = 0

func generate(on_progress: Callable = Callable()) -> void:
	ground_layer.clear()
	for x in range(biome_map.world_width):
		for y in range(biome_map.world_height):
			var biome := biome_map.get_biome_at(x, y)
			if biome:
				ground_layer.set_cell(Vector2i(x, y), tileset_source_id, biome.ground_atlas_coords)
		if x % 5 == 0:
			if on_progress.is_valid():
				on_progress.call(float(x) / biome_map.world_width)
			await get_tree().process_frame
