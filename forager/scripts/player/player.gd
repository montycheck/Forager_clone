extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite
@onready var camera: Camera2D = get_node_or_null("Camera2D")

const Config := preload("res://resources/config/player_config.tres")

var harvest_timer: float = 0.0
var _world_click_held: bool = false
var _highlight: HoverHighlight
var _pick_shape := CircleShape2D.new()
var _blink_tween: Tween
var _shake_tween: Tween

func _ready() -> void:
	PlayerVitals.hurt.connect(_on_hurt)
	_pick_shape.radius = 6.0
	_highlight = HoverHighlight.new()
	add_child(_highlight)

# Un menu (sauf le placement de bâtiment) bloque le monde
func _menu_blocks_world() -> bool:
	return UIManager.has_menu_open() and UIManager.current_menu != "build"

func _physics_process(delta: float) -> void:
	if _menu_blocks_world():
		_world_click_held = false
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()
	velocity = input_direction * Config.move_speed * PlayerStats.get_value(StatModifier.Stat.MOVE_SPEED)
	move_and_slide()

	harvest_timer += delta

	# Le clic doit avoir commencé dans le monde (pas sur une UI)
	_world_click_held = _world_click_held and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if _world_click_held and not BuildManager.is_placing:
		var target := _get_target_under_mouse()
		if target != null and target.has_method("hit") and _in_reach(target):
			if harvest_timer >= _get_effective_harvest_delay():
				target.hit(PlayerStats.get_hit_power())
				PlayerVitals.consume_hunger()
				harvest_timer = 0.0

func _process(_delta: float) -> void:
	_update_hover()

func _get_effective_harvest_delay() -> float:
	var multiplier: float = PlayerProgress.harvest_speed_multiplier * PlayerStats.get_value(StatModifier.Stat.HARVEST_SPEED)
	return Config.harvest_delay / max(multiplier, 0.01)

# --- Ciblage à la souris ---
func _get_target_under_mouse() -> Node2D:
	var mouse_pos := get_global_mouse_position()

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _pick_shape
	query.transform = Transform2D(0.0, mouse_pos)
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var best: Node2D = null
	var best_dist := INF
	for result in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var candidate = result["collider"].get_parent()
		if candidate == null or candidate == self or not candidate is Node2D:
			continue
		if not (candidate.has_method("hit") or candidate.has_method("interact")):
			continue
		var dist := mouse_pos.distance_to(candidate.global_position)
		if dist < best_dist:
			best_dist = dist
			best = candidate
	return best

func _in_reach(target: Node2D) -> bool:
	return global_position.distance_to(target.global_position) <= Config.interact_range

func _update_hover() -> void:
	var target: Node2D = null
	if not _menu_blocks_world() and not BuildManager.is_placing \
			and get_viewport().gui_get_hovered_control() == null:
		target = _get_target_under_mouse()

	if target == null:
		_highlight.set_target(null, true)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return

	var reachable := _in_reach(target)
	_highlight.set_target(target, reachable)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if reachable else Input.CURSOR_ARROW)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	# Pendant le placement : le clic gauche est géré par BuildManager
	if BuildManager.is_placing:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			BuildManager.cancel_placing()
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		_world_click_held = event.pressed
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var target := _get_target_under_mouse()
		if target != null and target.has_method("interact") and _in_reach(target):
			target.interact()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not _menu_blocks_world():
		_handle_mouse_button(event)

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

func save_data() -> Dictionary:
	return {
		"pos_x": global_position.x,
		"pos_y": global_position.y
	}

func load_data(data: Dictionary) -> void:
	global_position = Vector2(data["pos_x"], data["pos_y"])
