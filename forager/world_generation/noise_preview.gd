extends Node2D

@export var world_width: int = 100
@export var world_height: int = 100

@onready var biome_map: BiomeMap = $BiomeMap

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	for x in range(world_width):
		for y in range(world_height):
			var biome := biome_map.get_biome_at(x, y)
			var color := biome.debug_color if biome else Color.MAGENTA
			draw_rect(Rect2(x * 4, y * 4, 4, 4), color)
