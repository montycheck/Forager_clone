extends Node2D

@export var interval: float = 1.0

var allowed_ids: Array[String] = []
var is_ghost: bool = false
var timer: float = 0.0

func set_ghost(value: bool) -> void:
	is_ghost = value

func _ready() -> void:
	if is_ghost:
		return
	add_to_group("persist")
	add_to_group("importer")

func _process(delta: float) -> void:
	if is_ghost:
		return
	timer += delta
	if timer < interval:
		return
	timer = 0.0

	for node in get_tree().get_nodes_in_group("persist"):
		if node == self or not node.has_method("export_output"):
			continue
		if is_adjacent_to(node):
			node.export_output(self)

# Collé à un côté (les diagonales ne comptent pas)
func is_adjacent_to(other: Node2D) -> bool:
	var a := BuildManager.get_node_footprint(self)
	var b := BuildManager.get_node_footprint(other)
	return a.grow_individual(2, 0, 2, 0).intersects(b) or a.grow_individual(0, 2, 0, 2).intersects(b)

# --- Filtre ---
func accepts(item: Item) -> bool:
	if item is UpgradeItem:
		return false
	return allowed_ids.is_empty() or allowed_ids.has(item.id)

func is_allowed(item_id: String) -> bool:
	return allowed_ids.has(item_id)

func set_allowed(item_id: String, value: bool) -> void:
	if value and not allowed_ids.has(item_id):
		allowed_ids.append(item_id)
	elif not value:
		allowed_ids.erase(item_id)

func clear_filter() -> void:
	allowed_ids.clear()

# --- Interaction ---
func interact() -> void:
	var ui = get_tree().get_first_node_in_group("importer_config_ui")
	if ui != null:
		ui.open_for_importer(self)

# --- Sauvegarde ---
func save_state() -> Dictionary:
	return {"allowed": allowed_ids}

func load_state(data: Dictionary) -> void:
	allowed_ids.clear()
	for id in data.get("allowed", []):
		allowed_ids.append(str(id))
		
func get_config_title() -> String:
	return "Importeur"

func get_config_hint() -> String:
	return "Aucun item coché = tout est importé."
