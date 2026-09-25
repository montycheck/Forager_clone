extends CharacterBody2D

@export var speed: float = 100.0

var targets_in_range: Array = []

func _physics_process(delta: float) -> void:
	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()
	velocity = input_direction * speed
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var target := _get_closest_target()
		if target != null:
			if target.has_method("hit"):
				target.hit()
			elif target.has_method("interact"):
				target.interact()

	if event.is_action_pressed("debug_print_inventory"):
		Inventory.print_inventory()

	if event.is_action_pressed("toggle_craft"):
		get_tree().get_first_node_in_group("craft_ui").toggle()

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
