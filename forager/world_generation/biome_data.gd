extends Resource
class_name BiomeData

@export var biome_name: String = ""
@export var debug_color: Color = Color.WHITE

## Seuils de bruit : ce biome apparaît si la valeur de bruit
## est comprise entre noise_min et noise_max
@export var noise_min: float = -1.0
@export var noise_max: float = 1.0


@export var ground_atlas_coords: Vector2i = Vector2i.ZERO


@export var allowed_harvestables: Array[HarvestableData] = []
