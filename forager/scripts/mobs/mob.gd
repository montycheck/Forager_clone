extends CharacterBody2D
class_name Mob

signal died(mob: Mob)

@export var data: MobData

const PickupScene := preload("res://scenes/world/item_pickup.tscn")

const BAR_WIDTH := 28.0
const BAR_HEIGHT := 5.0
const BAR_OFFSET := Vector2(-BAR_WIDTH / 2.0, -26.0)   # au-dessus du mob, à ajuster
const KNOCKBACK_DECAY := 600.0                         # vitesse à laquelle le recul s'éteint

@onready var sprite: Sprite2D = $Sprite

var health: int = 1
var behavior: MobBehavior
var is_dying := false
var knockback := Vector2.ZERO

func _ready() -> void:
	add_to_group("mob")
	health = data.max_health
	sprite.texture = data.sprite_texture
	if data.behavior_script != null:
		behavior = data.behavior_script.new()
		behavior.setup(self)

	if not data.blocks_player:
		var player := get_player()
		if player != null:
			add_collision_exception_with(player)
			player.add_collision_exception_with(self)

func _physics_process(delta: float) -> void:
	if is_dying or behavior == null:
		return
	behavior.physics_update(delta)
	velocity += knockback
	move_and_slide()
	knockback = knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)

func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

# Appelé par le joueur (même contrat que ResourceNode)
func hit(power: int = 1) -> void:
	if is_dying:
		return
	health -= power
	queue_redraw()
	if health <= 0:
		_die()
		return

	var player := get_player()
	if player != null and data.knockback_force > 0.0:
		var away := global_position - player.global_position
		if away != Vector2.ZERO:
			knockback = away.normalized() * data.knockback_force

	if behavior != null:
		behavior.on_hit(player)

	modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1)

func _die() -> void:
	is_dying = true
	PlayerProgress.add_xp(data.xp_reward)
	_spawn_drops()
	died.emit(self)
	queue_free()

func _spawn_drops() -> void:
	var root := get_tree().get_first_node_in_group("y_sort_root")
	var luck := PlayerStats.get_luck()
	for entry in data.drops:
		var n = entry.roll(luck)
		if n <= 0:
			continue
		var pickup := PickupScene.instantiate()
		pickup.item = entry.item
		pickup.amount = n
		root.add_child(pickup)
		pickup.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))

func _draw() -> void:
	# Barre visible seulement une fois le mob blessé
	if is_dying or health >= data.max_health:
		return
	var ratio := clampf(float(health) / float(data.max_health), 0.0, 1.0)
	draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH, BAR_HEIGHT)), Color("#26262c"))
	var fill := Color("#5fd068") if ratio > 0.5 else (Color("#f5a623") if ratio > 0.25 else Color("#c0392b"))
	draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH * ratio, BAR_HEIGHT)), fill)
