extends Resource
class_name PlayerConfig

@export_group("Movement")
@export var move_speed: float = 400.0

@export_group("Harvest and Battle")
@export var base_hit_power: float = 1.0
@export var harvest_delay: float = 0.55
@export var base_luck: float = 1.0

@export_group("Vitals")
@export var max_health: float = 100.0
@export var max_hunger: float = 100.0
@export var hunger_per_hit: float = 2.0
@export var starvation_damage_per_second: float = 2.0
