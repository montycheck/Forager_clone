extends Node2D

@export var produced_item: Item
@export var produce_amount: int = 1
@export var production_time: float = 5.0

const PickupScene := preload("res://scenes/world/item_pickup.tscn")

var timer : float = 0.0
var is_ghost: bool = false

func _ready() -> void:
	add_to_group("persist")

func set_ghost(value: bool):
	is_ghost = value

func _process(delta: float) -> void:
	if is_ghost or produced_item == null:
		return
		
	timer += delta
	if timer >= production_time:
		timer = 0.0
		produce()

func produce() -> void:
	var pickup := PickupScene.instantiate()
	pickup.item = produced_item
	pickup.amount = produce_amount
	get_tree().get_first_node_in_group("y_sort_root").add_child(pickup)
	pickup.global_position = global_position + Vector2(0, 20) + Vector2(randf_range(-8, 8), randf_range(-8, 8))
