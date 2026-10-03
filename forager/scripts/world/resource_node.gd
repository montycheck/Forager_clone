extends Node2D

signal destroyed(node: Node2D)

@export var resource_name: String = "wood"
@export var item: Item
@export var max_hits: int = 3          # = vie max du node
@export var amount_per_hit: int = 1    # total droppé = amount_per_hit * max_hits
@export var sprite_texture: Texture2D

const PickupScene := preload("res://scenes/world/item_pickup.tscn")

const BAR_WIDTH := 28.0
const BAR_HEIGHT := 5.0
const BAR_OFFSET := Vector2(-BAR_WIDTH / 2.0, 20.0)   # sous le node, à ajuster
const DROP_RADIUS := 26.0

@onready var sprite: Sprite2D = $Sprite
@onready var occlusion_area: Area2D = get_node_or_null("OcclusionArea")

var current_hits: int = 0   # dégâts subis
var is_dying: bool = false

func _ready() -> void:
	if sprite_texture != null:
		sprite.texture = sprite_texture

	if occlusion_area != null:
		occlusion_area.body_entered.connect(_on_occlusion_body_entered)
		occlusion_area.body_exited.connect(_on_occlusion_body_exited)

func hit(power: int = 1) -> void:
	if is_dying:
		return
	var damage: int = mini(power, max_hits - current_hits)
	if damage <= 0:
		return

	current_hits += damage
	PlayerProgress.add_xp(2)
	queue_redraw()

	if current_hits >= max_hits:
		destroy()
		return

	modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1)

func destroy() -> void:
	is_dying = true
	_spawn_drops()
	destroyed.emit(self)
	queue_free()

func _spawn_drops() -> void:
	if item == null:
		return

	var root := get_tree().get_first_node_in_group("y_sort_root")
	var count := maxi(1, max_hits)

	for i in count:
		var pickup := PickupScene.instantiate()
		pickup.item = item
		pickup.amount = amount_per_hit
		root.add_child(pickup)
		pickup.global_position = global_position

		# Éjection en éventail avec un peu d'aléatoire
		var angle := (TAU / count) * i + randf_range(-0.4, 0.4)
		var target := global_position + Vector2.from_angle(angle) * randf_range(DROP_RADIUS * 0.6, DROP_RADIUS)
		var tween := pickup.create_tween()
		tween.tween_property(pickup, "global_position", target, 0.25) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	if current_hits <= 0 or is_dying:
		return
	var ratio := clampf(float(max_hits - current_hits) / float(max_hits), 0.0, 1.0)
	draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH, BAR_HEIGHT)), Color("#26262c"))
	var fill := Color("#5fd068") if ratio > 0.5 else (Color("#f5a623") if ratio > 0.25 else Color("#c0392b"))
	draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH * ratio, BAR_HEIGHT)), fill)

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
