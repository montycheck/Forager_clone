extends Node2D

@export var amount_per_tick: int = 4   # unités par item, toutes les 0,5 s

var allowed_ids: Array[String] = []
var is_ghost: bool = false

func set_ghost(value: bool) -> void:
	is_ghost = value

func _ready() -> void:
	if is_ghost:
		return
	add_to_group("persist")
	StorageNetwork.register_exporter(self)

func _exit_tree() -> void:
	StorageNetwork.unregister_exporter(self)

func is_adjacent_to(other: Node2D) -> bool:
	var a := BuildManager.get_node_footprint(self)
	var b := BuildManager.get_node_footprint(other)
	return a.grow_individual(2, 0, 2, 0).intersects(b) or a.grow_individual(0, 2, 0, 2).intersects(b)

# Tente de pousser l'item dans une machine collée. Renvoie la quantité acceptée.
func offer(item: Item, amount: int) -> int:
	for node in get_tree().get_nodes_in_group("persist"):
		if node == self or not node.has_method("accept_input"):
			continue
		if not is_adjacent_to(node):
			continue
		var accepted: int = node.accept_input(item, amount)
		if accepted > 0:
			return accepted
	return 0

# --- Filtre (même interface que l'importeur, pour réutiliser l'UI) ---
func is_allowed(item_id: String) -> bool:
	return allowed_ids.has(item_id)

func set_allowed(item_id: String, value: bool) -> void:
	if value and not allowed_ids.has(item_id):
		allowed_ids.append(item_id)
	elif not value:
		allowed_ids.erase(item_id)

func clear_filter() -> void:
	allowed_ids.clear()

func get_config_title() -> String:
	return "Exporteur"

func get_config_hint() -> String:
	return "Coche les items à envoyer à la machine collée."

# --- Interaction ---
func interact() -> void:
	var ui = get_tree().get_first_node_in_group("importer_config_ui")
	if ui != null:
		ui.open_for_importer(self)   # la même fenêtre sert aux deux

# --- Sauvegarde ---
func save_state() -> Dictionary:
	return {"allowed": allowed_ids}

func load_state(data: Dictionary) -> void:
	allowed_ids.clear()
	for id in data.get("allowed", []):
		allowed_ids.append(str(id))
