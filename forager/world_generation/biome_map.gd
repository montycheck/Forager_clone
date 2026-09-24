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
