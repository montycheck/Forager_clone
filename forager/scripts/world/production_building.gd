extends Node2D

@export var produced_item: Item
@export var produce_amount: int = 1
@export var production_time: float = 5.0
@export var max_storage: int = 99

const IndicatorFont := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const INDICATOR_OFFSET := Vector2(-20, 24)
const INDICATOR_ICON_SIZE := Vector2(16, 16)

var timer: float = 0.0
var stored: int = 0
var is_ghost: bool = false

func _ready() -> void:
	if is_ghost:
		return
	add_to_group("persist")
	_ensure_interaction_area()
	queue_redraw()

func set_ghost(value: bool) -> void:
	is_ghost = value

# Crée la zone de clic par script : aucune scène de bâtiment à modifier
func _ensure_interaction_area() -> void:
	if get_node_or_null("InteractionArea") != null:
		return
	var area := Area2D.new()
	area.name = "InteractionArea"
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)

func _process(delta: float) -> void:
	if is_ghost or produced_item == null:
		return

	timer += delta
	if timer >= production_time:
		# Si le stockage est plein, la machine attend (pas de perte, pas de cumul)
		if produce():
			timer = 0.0
		else:
			timer = production_time

# Renvoie false si rien n'a pu être produit (stockage plein)
func produce() -> bool:
	var remaining := _try_import()
	if remaining <= 0:
		return true   # tout est parti dans le réseau de stockage

	var space := max_storage - stored
	if space <= 0:
		return false

	stored += mini(space, remaining)
	queue_redraw()
	return true

# Renvoie la quantité qui n'a pas pu partir dans le réseau
func _try_import() -> int:
	var remaining := produce_amount
	for importer in get_tree().get_nodes_in_group("importer"):
		if remaining <= 0:
			break
		if importer.is_adjacent_to(self) and importer.accepts(produced_item):
			remaining -= StorageNetwork.add_item(produced_item, remaining)
	return remaining

# Appelé par les importeurs adjacents : vide aussi le stock interne
func export_output(importer: Node) -> void:
	if stored <= 0 or produced_item == null or not importer.accepts(produced_item):
		return
	var added := StorageNetwork.add_item(produced_item, stored)
	if added > 0:
		stored -= added
		queue_redraw()

# --- Collecte manuelle ---
func can_collect() -> bool:
	if stored <= 0 or produced_item == null:
		return false
	for slot in Inventory.slots:
		if slot["item"].id == produced_item.id and slot["amount"] < produced_item.max_stack:
			return true
	return Inventory.slots.size() < Inventory.max_slots

func collect() -> void:
	if not can_collect():
		return
	Inventory.add_item(produced_item, stored)
	stored = 0
	queue_redraw()

# --- Interaction (clic droit) ---
func interact() -> void:
	var ui = get_tree().get_first_node_in_group("production_ui")
	if ui != null:
		ui.open_for_building(self)

# --- Indicateur dans le monde ---
func _draw() -> void:
	if is_ghost or produced_item == null or stored <= 0:
		return
	if produced_item.icon != null:
		draw_texture_rect(produced_item.icon, Rect2(INDICATOR_OFFSET, INDICATOR_ICON_SIZE), false)
	var text_pos := INDICATOR_OFFSET + Vector2(INDICATOR_ICON_SIZE.x + 3, 13)
	var text := str(stored)
	draw_string(IndicatorFont, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, 0.6))
	draw_string(IndicatorFont, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f5a623"))

# --- Sauvegarde ---
func save_state() -> Dictionary:
	return {"stored": stored, "timer": timer}

func load_state(data: Dictionary) -> void:
	stored = clampi(int(data.get("stored", 0)), 0, max_storage)
	timer = float(data.get("timer", 0.0))
	queue_redraw()
