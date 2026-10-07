extends Node2D

const RequesterScene := preload("res://scenes/buildings/requester_building.tscn")
const GRID_SIZE := 32
const MAX_ATTEMPTS := 300

@export var biome_map: BiomeMap
@export var min_distance_from_center: float = 30.0  # en cases, force l'exploration

func spawn_requesters() -> void:
	for biome in biome_map.biomes:
		_spawn_requester_for_biome(biome)

func _spawn_requester_for_biome(biome: BiomeData) -> void:
	var pos = _find_valid_position(biome)
	if pos == null:
		push_warning("Impossible de placer le Requester pour le biome : " + biome.biome_name)
		return

	var instance := RequesterScene.instantiate()
	instance.biome_name = biome.biome_name
	get_tree().get_first_node_in_group("y_sort_root").add_child(instance)
	instance.global_position = pos

func _find_valid_position(biome: BiomeData):
	var center_x := biome_map.world_width / 2.0
	var center_y := biome_map.world_height / 2.0

	for attempt in MAX_ATTEMPTS:
		var tile_x := randi_range(0, biome_map.world_width - 1)
		var tile_y := randi_range(0, biome_map.world_height - 1)

		if biome_map.get_biome_at(tile_x, tile_y) != biome:
			continue

		var dist := Vector2(tile_x - center_x, tile_y - center_y).length()
		if dist < min_distance_from_center:
			continue

		var world_pos := Vector2(
			tile_x * GRID_SIZE + GRID_SIZE / 2,
			tile_y * GRID_SIZE + GRID_SIZE / 2
		)

		if _is_position_free(world_pos):
			return world_pos

	return null

func _is_position_free(pos: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var results := space_state.intersect_point(query)
	return results.is_empty()
