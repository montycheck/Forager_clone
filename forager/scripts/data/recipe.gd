extends Resource
class_name Recipe

@export var output_item: Item
@export var output_amount: int = 1

@export var input_items: Array[Item] = []
@export var input_amounts : Array[int] = []

@export var required_skill_id: String = ""
