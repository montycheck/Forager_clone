extends Node2D

const GRID_SIZE := 32
const MAX_ATTEMPTS_PER_RESOURCE := 40

@export var biome_map: BiomeMap
@export var min_spacing: float = 40.0

var spawned_positions: Array[Vector2] = []

func generate_resources() -> void:
	spawned_positions.clear()

	for child in get_children():
		child.queue_free()

	for biome in biome_map.biomes:
		for data in biome.allowed_harvestables:
			for i in data.spawn_count:
				_try_spawn(data, biome)

func _try_spawn(data: HarvestableData, biome: BiomeData) -> void:
	var pos = _find_valid_position(biome)
	if pos == null:
		return
	_spawn_at(data, biome, pos)

func _find_valid_position(biome: BiomeData, max_attempts: int = MAX_ATTEMPTS_PER_RESOURCE):
	for attempt in max_attempts:
		var tile_x := randi_range(0, biome_map.world_width - 1)
		var tile_y := randi_range(0, biome_map.world_height - 1)

		if biome_map.get_biome_at(tile_x, tile_y) != biome:
			continue

		var world_pos := Vector2(
			tile_x * GRID_SIZE + GRID_SIZE / 2,
			tile_y * GRID_SIZE + GRID_SIZE / 2
		)

		if _is_far_enough(world_pos) and _is_position_free(world_pos):
			return world_pos

	return null

func _is_far_enough(pos: Vector2) -> bool:
	for p in spawned_positions:
		if p.distance_to(pos) < min_spacing:
			return false
	return true

func _is_position_free(pos: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var results := space_state.intersect_point(query)
	return results.is_empty()

func _spawn_at(data: HarvestableData, biome: BiomeData, pos: Vector2) -> void:
	var node := data.scene.instantiate()
	node.resource_name = data.id
	node.item = data.item
	node.max_hits = data.max_hits
	node.amount_per_hit = data.amount_per_hit
	node.sprite_texture = data.sprite_texture
	node.position = pos

	get_tree().get_first_node_in_group("y_sort_root").add_child.call_deferred(node)
	spawned_positions.append(pos)

	node.destroyed.connect(_on_resource_destroyed.bind(data, biome))

func _on_resource_destroyed(_node: Node2D, data: HarvestableData, biome: BiomeData) -> void:
	await get_tree().create_timer(data.respawn_time).timeout
	_try_spawn(data, biome)
