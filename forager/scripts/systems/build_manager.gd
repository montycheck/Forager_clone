extends Node

const GRID_SIZE := 32

var is_placing: bool = false
var current_building: Building = null
var ghost: Node2D = null
var can_place: bool = false

func _ready() -> void:
	UIManager.menu_closed.connect(_on_menu_closed)

func start_placing(building: Building) -> void:
	if building.required_skill_id != "" and not PlayerProgress.is_skill_unlocked(building.required_skill_id):
		return

	if is_placing and current_building == building:
		cancel_placing()
		return

	if is_placing:
		_cleanup_placing()

	current_building = building
	is_placing = true

	ghost = building.scene.instantiate()
	_disable_ghost_collisions(ghost)

	if ghost.has_method("set_ghost"):
		ghost.set_ghost(true)

	get_tree().get_first_node_in_group("y_sort_root").add_child(ghost)

	UIManager.open_menu("build")

func _disable_ghost_collisions(node: Node) -> void:
	if node is CollisionShape2D:
		node.set_deferred("disabled", true)

	for child in node.get_children():
		_disable_ghost_collisions(child)

func _process(_delta: float) -> void:
	if not is_placing or ghost == null:
		return

	var mouse_pos: Vector2 = ghost.get_global_mouse_position()
	var snapped_x: float = floor(mouse_pos.x / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	var snapped_y: float = floor(mouse_pos.y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	var snapped_pos := Vector2(snapped_x, snapped_y)

	ghost.global_position = snapped_pos

	var overlap_ok := _check_overlap(snapped_pos)
	var cost_ok := Inventory.has_items(current_building.cost_items, current_building.cost_amounts)
	can_place = overlap_ok and cost_ok

	if can_place:
		ghost.modulate = Color(0, 1, 0, 0.5)
	else:
		ghost.modulate = Color(1, 0, 0, 0.5)

func _check_overlap(position: Vector2) -> bool:
	var space_state := ghost.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var results := space_state.intersect_point(query)
	return results.is_empty()

func _unhandled_input(event: InputEvent) -> void:
	if not is_placing:
		return

	if event.is_action_pressed("place_building"):
		confirm_placement()

func confirm_placement() -> void:
	if not can_place:
		return

	Inventory.remove_items(current_building.cost_items, current_building.cost_amounts)

	var building_instance := current_building.scene.instantiate()
	get_tree().get_first_node_in_group("y_sort_root").add_child(building_instance)
	building_instance.global_position = ghost.global_position

	PlayerProgress.add_xp(20)

	UIManager.close_menu()

func cancel_placing() -> void:
	UIManager.close_menu()

func _cleanup_placing() -> void:
	if ghost != null:
		ghost.queue_free()
		ghost = null

	is_placing = false
	current_building = null
	can_place = false

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "build":
		_cleanup_placing()
