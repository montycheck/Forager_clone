extends Node
class_name BiomeMap

@export var noise_scale: float = 0.015
@export var world_seed: int = 0
@export var biomes: Array[BiomeData] = []

@export var water_biome: BiomeData
@export var world_width: int = 200
@export var world_height: int = 200
@export var water_threshold: float = 0.75  # 0 = tout en eau, 1 = jamais d'eau
@export var coast_noise_scale: float = 0.01
@export var coast_variation: float = 0.15
@export var blend_width: float = 0.05
@export var blend_noise_scale: float = 0.2

var blend_noise := FastNoiseLite.new()

var noise := FastNoiseLite.new()
var coast_noise := FastNoiseLite.new()

func _ready() -> void:
	setup(world_seed)

func setup(seed_value: int) -> void:
	world_seed = seed_value
	noise.seed = world_seed
	noise.frequency = noise_scale
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_octaves = 2
	noise.fractal_gain = 0.3
	
	coast_noise.seed = world_seed + 1
	coast_noise.frequency = coast_noise_scale
	coast_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	coast_noise.fractal_octaves = 2
	
	blend_noise.seed = world_seed + 2
	blend_noise.frequency = blend_noise_scale
	blend_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

## Renvoie la valeur brute de bruit à une position donnée (en coordonnées de tuile)
func get_noise_value(tile_x: int, tile_y: int) -> float:
	return noise.get_noise_2d(tile_x, tile_y)

func get_land_distance(tile_x: int, tile_y: int):
	var center_x := world_width / 2.0
	var center_y := world_height / 2.0
	var dx := (tile_x - center_x) / (world_width / 2.0)
	var dy := (tile_y - center_y) / (world_height / 2.0)
	var dist := sqrt(dx * dx + dy * dy)
	dist += coast_noise.get_noise_2d(tile_x, tile_y) * coast_variation
	return dist

## Renvoie le BiomeData correspondant à une position (en coordonnées de tuile)
func get_biome_at(tile_x: int, tile_y: int) -> BiomeData:
	if get_land_distance(tile_x, tile_y) > water_threshold:
		return water_biome
	var value := get_noise_value(tile_x, tile_y)
	for biome in biomes:
		if value >= biome.noise_min and value < biome.noise_max:
			return biome
	# Sécurité : si aucun biome ne matche (trou dans les seuils), on renvoie le premier
	return biomes[0] if biomes.size() > 0 else null
	
func _find_biome_index_for_value(value: float) -> int:
	for i in biomes.size():
		if value >= biomes[i].noise_min and value < biomes[i].noise_max:
			return i
	return -1

## Comme get_biome_at, mais mélange les tuiles près des frontières (usage visuel uniquement)
func get_ground_biome_at(tile_x: int, tile_y: int) -> BiomeData:
	if get_land_distance(tile_x, tile_y) > water_threshold:
		return water_biome

	var value := get_noise_value(tile_x, tile_y)
	var index := _find_biome_index_for_value(value)
	if index == -1:
		return biomes[0] if biomes.size() > 0 else null

	var current_biome := biomes[index]
	var dist_to_max := current_biome.noise_max - value
	var dist_to_min := value - current_biome.noise_min

	var neighbor_index := -1
	var blend_factor := 0.0

	if dist_to_max < blend_width and index < biomes.size() - 1:
		neighbor_index = index + 1
		blend_factor = 1.0 - (dist_to_max / blend_width)
	elif dist_to_min < blend_width and index > 0:
		neighbor_index = index - 1
		blend_factor = 1.0 - (dist_to_min / blend_width)

	if neighbor_index != -1:
		var dither := (blend_noise.get_noise_2d(tile_x, tile_y) + 1.0) / 2.0
		if dither < blend_factor * 0.5:
			return biomes[neighbor_index]

	return current_biome
	
## Calcule la proportion de terre occupée par chaque biome (0.0 à 1.0)
func get_biome_coverage() -> Dictionary:
	var counts := {}
	for biome in biomes:
		counts[biome] = 0

	var land_total := 0

	for x in range(world_width):
		for y in range(world_height):
			if get_land_distance(x, y) > water_threshold:
				continue
			var value := get_noise_value(x, y)
			var index := _find_biome_index_for_value(value)
			if index != -1:
				counts[biomes[index]] += 1
				land_total += 1

	var ratios := {}
	for biome in biomes:
		ratios[biome] = float(counts[biome]) / float(max(land_total, 1))
	return ratios

func has_all_biomes_represented(min_ratio: float = 0.05) -> bool:
	var ratios := get_biome_coverage()
	for biome in biomes:
		if ratios[biome] < min_ratio:
			return false
	return true

## Proportion de terre (hors eau) sur l'ensemble de la carte
func get_land_ratio() -> float:
	var land_count := 0
	for x in range(world_width):
		for y in range(world_height):
			if get_land_distance(x, y) <= water_threshold:
				land_count += 1
	return float(land_count) / float(world_width * world_height)
