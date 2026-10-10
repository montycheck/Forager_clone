extends Node

signal health_changed
signal hunger_changed
signal died
signal hurt

const Config := preload("res://resources/config/player_config.tres")

var max_health: float
var max_hunger: float
var health: float
var hunger: float
var hunger_per_hit: float
var starvation_damage_per_second: float

func _ready() -> void:
	max_health = Config.max_health
	max_hunger = Config.max_hunger
	hunger_per_hit = Config.hunger_per_hit
	starvation_damage_per_second = Config.starvation_damage_per_second
	health = max_health
	hunger = max_hunger

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
	
func damage(amount: float, feedback: bool = false):
	if health <= 0.0:
		return
	health = clampf(health - amount, 0.0, max_health)
	health_changed.emit()
	if feedback:
		hurt.emit()
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
	
