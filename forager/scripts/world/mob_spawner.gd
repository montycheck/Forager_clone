extends Node2D

const MobScene := preload("res://scenes/mobs/mob.tscn")
const GRID_SIZE := 32
const MAX_ATTEMPTS := 40
const MIN_DISTANCE_FROM_PLAYER := 200.0   # un mob ne réapparaît pas sous le nez du joueur

@export var biome_map: BiomeMap

func generate_mobs() -> void:
	for biome in biome_map.biomes:
		for data in biome.allowed_mobs:
			for i in data.spawn_count:
				_try_spawn(data, biome, false)

func _try_spawn(data: MobData, biome: BiomeData, avoid_player: bool) -> void:
	var pos = _find_position(biome, avoid_player)
	if pos == null:
		return
	var mob := MobScene.instantiate()
	mob.data = data
	get_tree().get_first_node_in_group("y_sort_root").add_child(mob)
	mob.global_position = pos
	mob.died.connect(_on_mob_died.bind(data, biome))

func _on_mob_died(_mob: Mob, data: MobData, biome: BiomeData) -> void:
	if data.respawn_time <= 0.0:
		return
	await get_tree().create_timer(data.respawn_time).timeout
	_try_spawn(data, biome, true)

func _find_position(biome: BiomeData, avoid_player: bool):
	var player := get_tree().get_first_node_in_group("player")
	for attempt in MAX_ATTEMPTS:
		var tx := randi_range(0, biome_map.world_width - 1)
		var ty := randi_range(0, biome_map.world_height - 1)
		if biome_map.get_biome_at(tx, ty) != biome:
			continue
		var pos := Vector2(tx * GRID_SIZE + GRID_SIZE / 2, ty * GRID_SIZE + GRID_SIZE / 2)
		if avoid_player and player != null and pos.distance_to(player.global_position) < MIN_DISTANCE_FROM_PLAYER:
			continue
		var query := PhysicsPointQueryParameters2D.new()
		query.position = pos
		query.collide_with_bodies = true
		query.collide_with_areas = false
		if get_world_2d().direct_space_state.intersect_point(query).is_empty():
			return pos
	return null
