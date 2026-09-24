extends Resource
class_name HarvestableData

@export var id: String = ""
@export var item: Item
@export var sprite_texture: Texture2D
@export var max_hits: int = 3
@export var amount_per_hit: int = 1
@export var spawn_count: int = 6
@export var respawn_time: float = 20.0
@export var scene: PackedScene
