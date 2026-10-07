extends Node

const GRID_SIZE := 32
const BUILDINGS_FOLDER := "res://resources/buildings/"

var is_placing: bool = false
var current_building: Building = null
var ghost: Node2D = null
var can_place: bool = false

# chemin de la scène -> taille en cases (sert à connaître l'empreinte des bâtiments déjà posés)
var _grid_sizes: Dictionary = {}

func _ready() -> void:
	UIManager.menu_closed.connect(_on_menu_closed)
	_cache_grid_sizes()

func _cache_grid_sizes() -> void:
	var dir := DirAccess.open(BUILDINGS_FOLDER)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var b = load(BUILDINGS_FOLDER + file_name)
			if b is Building and b.scene != null:
				_grid_sizes[b.scene.resource_path] = b.grid_size
		file_name = dir.get_next()
	dir.list_dir_end()

func start_placing(building: Building) -> void:
	var skill_ok := building.required_skill_id == "" or PlayerProgress.is_skill_unlocked(building.required_skill_id)
	var stage_ok := building.required_stage_id == "" or PlayerProgress.is_stage_validated(building.required_stage_id)

	if not (skill_ok and stage_ok):
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
	var snapped_pos := _snap(mouse_pos, current_building.grid_size)
	ghost.global_position = snapped_pos

	var overlap_ok := _check_overlap(snapped_pos)
	var cost_ok := Inventory.has_items(current_building.cost_items, current_building.cost_amounts)
	can_place = overlap_ok and cost_ok

	if can_place:
		ghost.modulate = Color(0, 1, 0, 0.5)
	else:
		ghost.modulate = Color(1, 0, 0, 0.5)

# Taille impaire -> centré au milieu d'une case. Taille paire -> centré sur un croisement de grille.
func _snap(p: Vector2, gs: Vector2i) -> Vector2:
	var x: float
	var y: float
	if gs.x % 2 == 1:
		x = floor(p.x / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2.0
	else:
		x = round(p.x / GRID_SIZE) * GRID_SIZE
	if gs.y % 2 == 1:
		y = floor(p.y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2.0
	else:
		y = round(p.y / GRID_SIZE) * GRID_SIZE
	return Vector2(x, y)

# Rectangle occupé par un bâtiment centré en `center`
func _get_footprint(center: Vector2, gs: Vector2i) -> Rect2:
	var size := Vector2(gs) * GRID_SIZE
	return Rect2(center - size / 2.0, size)

func _check_overlap(pos: Vector2) -> bool:
	var gs: Vector2i = current_building.grid_size
	var rect := _get_footprint(pos, gs)

	# 1) Autres bâtiments : on compare les empreintes (collés côte à côte = OK)
	for node in get_tree().get_nodes_in_group("persist"):
		if node == ghost:
			continue
		var other_gs: Vector2i = _grid_sizes.get(node.scene_file_path, Vector2i(1, 1))
		if rect.intersects(_get_footprint(node.global_position, other_gs)):
			return false

	# 2) Ressources, eau, joueur... : test physique au centre de chaque case de l'empreinte
	var space_state := ghost.get_world_2d().direct_space_state
	for ix in gs.x:
		for iy in gs.y:
			var query := PhysicsPointQueryParameters2D.new()
			query.position = rect.position + Vector2((ix + 0.5) * GRID_SIZE, (iy + 0.5) * GRID_SIZE)
			query.collide_with_bodies = true
			query.collide_with_areas = false
			for r in space_state.intersect_point(query):
				var col = r["collider"]
				if col is Node and col.get_parent() != null and col.get_parent().is_in_group("persist"):
					continue   # bâtiment : déjà géré par le test d'empreintes
				return false
	return true

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
