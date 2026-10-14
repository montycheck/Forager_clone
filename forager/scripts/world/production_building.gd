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
	var remaining := _try_import()
	if remaining <= 0:
		return

	var pickup := PickupScene.instantiate()
	pickup.item = produced_item
	pickup.amount = remaining
	get_tree().get_first_node_in_group("y_sort_root").add_child(pickup)
	pickup.global_position = global_position + Vector2(0, 20) + Vector2(randf_range(-8, 8), randf_range(-8, 8))

# Renvoie la quantité qui n'a pas pu partir dans le réseau
func _try_import() -> int:
	var remaining := produce_amount
	for importer in get_tree().get_nodes_in_group("importer"):
		if remaining <= 0:
			break
		if importer.is_adjacent_to(self) and importer.accepts(produced_item):
			remaining -= StorageNetwork.add_item(produced_item, remaining)
	return remaining
