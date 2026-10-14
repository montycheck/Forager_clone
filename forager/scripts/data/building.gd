extends Resource
class_name Building

enum Category { MACHINES, PASSIVE_PRODUCTION, STORAGE }

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
@export var scene: PackedScene
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var category: Category = Category.MACHINES

@export var cost_items: Array[Item] = []
@export var cost_amounts: Array[int] = []

@export var required_skill_id: String = ""
@export var required_stage_id: String = ""
