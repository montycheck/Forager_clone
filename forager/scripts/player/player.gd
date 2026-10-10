extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite
@onready var camera: Camera2D = get_node_or_null("Camera2D")

const Config := preload("res://resources/config/player_config.tres")

var targets_in_range: Array = []
var harvest_timer: float = 0.0
var _blink_tween: Tween
var _shake_tween: Tween

func _ready() -> void:
	PlayerVitals.hurt.connect(_on_hurt)

func _physics_process(delta: float) -> void:
	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()
	velocity = input_direction * Config.move_speed * PlayerStats.get_value(StatModifier.Stat.MOVE_SPEED)
	move_and_slide()

	harvest_timer += delta

	if Input.is_action_pressed("interact"):
		var target := _get_closest_target()
		if target != null and target.has_method("hit"):
			if harvest_timer >= _get_effective_harvest_delay():
				target.hit(PlayerStats.get_hit_power())
				PlayerVitals.consume_hunger()
				harvest_timer = 0.0

func _get_effective_harvest_delay() -> float:
	var multiplier: float = PlayerProgress.harvest_speed_multiplier * PlayerStats.get_value(StatModifier.Stat.HARVEST_SPEED)
	return Config.harvest_delay / max(multiplier, 0.01)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var target := _get_closest_target()
		if target != null and target.has_method("interact"):
			target.interact()

	if event.is_action_pressed("debug_print_inventory"):
		Inventory.print_inventory()

	if event.is_action_pressed("toggle_skills"):
		get_tree().get_first_node_in_group("skill_tree_ui").toggle()

	if event.is_action_pressed("toggle_build_menu"):
		get_tree().get_first_node_in_group("build_menu_ui").toggle()

	if event.is_action_pressed("toggle_pause"):
		if BuildManager.is_placing:
			BuildManager.cancel_placing()
		elif UIManager.has_menu_open():
			UIManager.close_menu()
		else:
			get_tree().get_first_node_in_group("pause_menu").toggle()

func _get_closest_target() -> Node2D:
	if targets_in_range.is_empty():
		return null

	var closest: Node2D = null
	var closest_dist := INF

	for target in targets_in_range:
		if not is_instance_valid(target):
			continue
		var dist := global_position.distance_to(target.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = target

	return closest

func _on_hurt() -> void:
	# Clignotement rouge
	if _blink_tween:
		_blink_tween.kill()
	sprite.modulate = Color.WHITE
	_blink_tween = create_tween()
	for i in 3:
		_blink_tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 0.4), 0.06)
		_blink_tween.tween_property(sprite, "modulate", Color.WHITE, 0.06)

	# Secousse de la caméra
	if camera == null:
		return
	if _shake_tween:
		_shake_tween.kill()
	camera.offset = Vector2.ZERO
	_shake_tween = create_tween()
	for i in 6:
		var strength := 6.0 * (1.0 - i / 6.0)
		_shake_tween.tween_property(camera, "offset", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.03)
	_shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)

func _on_interaction_range_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.has_method("hit") or parent.has_method("interact"):
		targets_in_range.append(parent)

func _on_interaction_range_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	targets_in_range.erase(parent)

func save_data() -> Dictionary:
	return {
		"pos_x": global_position.x,
		"pos_y": global_position.y
	}

func load_data(data: Dictionary) -> void:
	global_position = Vector2(data["pos_x"], data["pos_y"])
