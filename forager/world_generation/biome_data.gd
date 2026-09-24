extends Resource
class_name BiomeData

@export var biome_name: String = ""
@export var debug_color: Color = Color.WHITE

## Seuils de bruit : ce biome apparaît si la valeur de bruit
## est comprise entre noise_min et noise_max
@export var noise_min: float = -1.0
@export var noise_max: float = 1.0

## La tuile de sol utilisée pour ce biome (on la reliera à l'étape 3)
@export var ground_atlas_coords: Vector2i = Vector2i.ZERO

## Pour plus tard : ressources autorisées dans ce biome
@export var allowed_harvestables: Array[HarvestableData] = []
