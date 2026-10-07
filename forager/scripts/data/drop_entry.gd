extends Resource
class_name DropEntry

@export var item: Item
@export var min_amount: int = 1
@export var max_amount: int = 1
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0
@export var luck_affects_chance: bool = true

func roll(luck: float):
	if item == null:
		return 0
	var c := chance
	if luck_affects_chance:
		c = clampf(chance * luck, 0.0, 1.0)
	if randf() >= c:
		return 0
	return randi_range(min_amount, maxi(min_amount, max_amount))
