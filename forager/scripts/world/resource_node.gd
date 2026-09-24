extends Node2D

signal destroyed(node: Node2D)

@export var resource_name: String = "wood"
@export var item: Item
@export var max_hits: int = 3
@export var amount_per_hit: int = 1
@export var sprite_texture: Texture2D

const PickupScene := preload("res://scenes/world/item_pickup.tscn")

@onready var sprite: Sprite2D = $Sprite

@onready var occlusion_area: Area2D = get_node_or_null("OcclusionArea")

var current_hits: int = 0

func _ready() -> void:
	if sprite_texture != null:
		sprite.texture = sprite_texture
		
	if occlusion_area != null:
		occlusion_area.body_entered.connect(_on_occlusion_body_entered)
		occlusion_area.body_exited.connect(_on_occlusion_body_exited)
		
func hit():
	current_hits += 1
	spawn_pickup()
	PlayerProgress.add_xp(2)
	modulate = Color(2,2,2)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1,1,1)
	if current_hits >= max_hits:
		destroy()
		
func spawn_pickup() -> void:
	if item == null:
		return

	var pickup := PickupScene.instantiate()
	pickup.item = item
	pickup.amount = amount_per_hit
	get_tree().get_first_node_in_group("y_sort_root").add_child(pickup)
	pickup.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		
func destroy():
	destroyed.emit(self)
	queue_free()
	
func _on_occlusion_body_entered(body: Node2D):
	if body.is_in_group("player"):
		_set_transparent(true)
		
func _on_occlusion_body_exited(body: Node2D):
	if body.is_in_group("player"):
		_set_transparent(false)
		
func _set_transparent(value: bool):
	var target_alpha := 0.45 if value else 1.0
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", target_alpha, 0.15)
		
