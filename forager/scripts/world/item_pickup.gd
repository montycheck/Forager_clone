extends Area2D

@export var item: Item
@export var amount: int = 1
@export var attract_speed: float = 250.0
@export var attract_radius: float = 60.0
@export var pickup_delay: float = 0.6   # temps pendant lequel l'item reste visible, non ramassable

@onready var sprite: Sprite2D = $Sprite

var player_ref: Node2D = null
var age: float = 0.0
var can_collect: bool = false
var collected: bool = false

func _ready() -> void:
	if item != null:
		sprite.texture = item.icon

	scale = Vector2(0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if collected:
		return

	if not can_collect:
		age += delta
		if age >= pickup_delay:
			can_collect = true
			_collect_if_player_inside()
		return

	if player_ref == null:
		player_ref = _find_player_in_radius()
		return
	var direction := (player_ref.global_position - global_position).normalized()
	global_position += direction * attract_speed * delta

func _find_player_in_radius():
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	if global_position.distance_to(player.global_position) <= attract_radius:
		return player
	return null

func _collect_if_player_inside() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_collect()
			return

func _on_body_entered(body: Node2D) -> void:
	if not can_collect or collected:
		return
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if collected:
		return
	collected = true
	Inventory.add_item(item, amount)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
	tween.tween_callback(queue_free)
