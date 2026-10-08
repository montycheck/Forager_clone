extends Node

signal health_changed
signal hunger_changed
signal died

@export var max_health: float = 100.0
@export var max_hunger: float = 100.0
var health: float = 100.0
var hunger: float = 100.0

@export var hunger_per_hit: float = 2.0
@export var starvation_damage_per_second: float = 2.0

func _process(delta: float) -> void:
	if hunger <= 0.0 and health > 0.0:
		damage(starvation_damage_per_second * delta)
		
func consume_hunger(amount: float = -1.0):
	if amount < 0.0:
		amount = hunger_per_hit
	hunger = clampf(hunger-amount, 0, max_hunger)
	hunger_changed.emit()
	
func restore_hunger(amount: float):
	hunger = clampf(hunger + amount, 0.0, max_hunger)
	
func damage(amount: float):
	if health <= 0.0:
		return
	health = clampf(health - amount, 0.0, max_health)
	health_changed.emit()
	if health <= 0.0:
		died.emit()
		_on_died()

func heal(amount: float):
	health = clampf(health + amount, 0.0, max_health)
	health_changed.emit()
	
func _on_died():
	print("You are dead")
	reset()
	
func reset():
	health = max_health
	hunger = max_hunger
	health_changed.emit()
	hunger_changed.emit()
	
func save_data():
	return {"health":health, "hunger":hunger}
	
func load_data(data: Dictionary) -> void:
	health = data.get("health", max_health)
	hunger = data.get("hunger", max_hunger)
	health_changed.emit()
	hunger_changed.emit()
	
