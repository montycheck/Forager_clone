extends Node2D

@export var building_id: String = ""
@export var station_display_name: String = ""

@onready var output_icon: TextureRect = get_node_or_null("OutputIcon")
@onready var output_label: Label = get_node_or_null("OutputLabel")

var is_ghost: bool = false
var active_recipe: Recipe = null   # recette du lot en cours (null = libre)
var remaining_crafts: int = 0      # crafts restants dans le lot
var output_stock: Dictionary = {}
var timer: float = 0.0

const MAX_BATCH := 99
const BAR_WIDTH := 32.0
const BAR_HEIGHT := 5.0
const BAR_OFFSET := Vector2(-BAR_WIDTH / 2.0, 38.0)

const IndicatorFont := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const INDICATOR_ICON_SIZE := Vector2(16, 16)
const INDICATOR_OFFSET := Vector2(-20, 20)   # sous le bâtiment, ajuste si besoin

func _ready() -> void:
	add_to_group("persist")

	if output_icon != null:
		output_icon.size = Vector2(16, 16)
		output_icon.position = Vector2(-24, -32)

	if output_label != null:
		output_label.size = Vector2(24, 16)
		output_label.position = Vector2(-6, -32)

	_update_output_label()

func set_ghost(value: bool) -> void:
	is_ghost = value

func is_busy() -> bool:
	return remaining_crafts > 0

# Nombre max de crafts possibles avec l'inventaire actuel
func get_max_craftable(recipe: Recipe) -> int:
	if recipe == null or not recipe.is_unlocked():
		return 0

	var result := MAX_BATCH
	for i in recipe.input_items.size():
		var needed: int = recipe.input_amounts[i]
		if needed <= 0:
			continue
		var have := Inventory.get_item_amount(recipe.input_items[i])
		result = mini(result, int(have / float(needed)))

	# Un upgrade ne se craft qu'une fois, et pas s'il attend d'être collecté
	if recipe.output_item is UpgradeItem:
		if output_stock.has(recipe.output_item.id):
			return 0
		result = mini(result, 1)

	return maxi(result, 0)

# Lance un lot : prélève les ingrédients dans l'inventaire
func start_batch(recipe: Recipe, count: int) -> bool:
	if is_busy() or recipe == null:
		return false
	if count <= 0 or count > get_max_craftable(recipe):
		return false

	var amounts: Array[int] = []
	for a in recipe.input_amounts:
		amounts.append(a * count)
	Inventory.remove_items(recipe.input_items, amounts)

	active_recipe = recipe
	remaining_crafts = count
	timer = 0.0
	return true

func _process(delta: float) -> void:
	if is_ghost:
		return

	if remaining_crafts > 0 and active_recipe != null:
		timer += delta
		if timer >= active_recipe.production_time:
			timer = 0.0
			_craft_once()

	queue_redraw()

func _craft_once() -> void:
	var out_item := active_recipe.output_item
	if output_stock.has(out_item.id):
		output_stock[out_item.id]["amount"] += active_recipe.output_amount
	else:
		output_stock[out_item.id] = {"item": out_item, "amount": active_recipe.output_amount}

	remaining_crafts -= 1
	if remaining_crafts <= 0:
		remaining_crafts = 0
		active_recipe = null
		timer = 0.0

	_update_output_label()

func _draw() -> void:
		if is_ghost or active_recipe == null:
			return

		# Barre de progression (inchangée)
		var progress := 0.0
		if active_recipe.production_time > 0.0:
			progress = clamp(timer / active_recipe.production_time, 0.0, 1.0)

		draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH, BAR_HEIGHT)), Color("#26262c"))
		draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH * progress, BAR_HEIGHT)), Color("#5fd068"))

		# Indicateur : item en cours de production + crafts restants
		var icon: Texture2D = active_recipe.output_item.icon
		if icon != null:
			draw_texture_rect(icon, Rect2(INDICATOR_OFFSET, INDICATOR_ICON_SIZE), false)

		var text_pos := INDICATOR_OFFSET + Vector2(INDICATOR_ICON_SIZE.x + 3, 13)
		var text := "x%d" % remaining_crafts
		draw_string(IndicatorFont, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, 0.6))
		draw_string(IndicatorFont, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f5a623"))

func get_output_total() -> int:
	var total := 0
	for id in output_stock:
		total += output_stock[id]["amount"]
	return total

func get_first_output_item() -> Item:
	if output_stock.is_empty():
		return null
	return output_stock[output_stock.keys()[0]]["item"]

func collect_output() -> void:
	for id in output_stock.keys():
		var entry = output_stock[id]
		Inventory.add_item(entry["item"], entry["amount"])
	output_stock.clear()
	_update_output_label()

func _update_output_label() -> void:
	if output_icon == null or output_label == null:
		return

	var total := get_output_total()
	var show := total > 0

	output_icon.visible = show
	output_label.visible = show

	if show:
		output_label.text = str(total)
		output_icon.texture = get_first_output_item().icon

func interact() -> void:
	var ui = get_tree().get_first_node_in_group("crafting_station_ui")
	ui.open_for_station(self)
