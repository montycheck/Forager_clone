extends Node2D

@export var building_id: String = ""
@export var station_display_name: String = ""

@onready var output_icon: TextureRect = get_node_or_null("OutputIcon")
@onready var output_label: Label = get_node_or_null("OutputLabel")
@onready var sprite: Sprite2D = $Sprite

var is_ghost: bool = false
var active_recipe: Recipe = null   # recette du craft/lot en cours (null = libre)
var remaining_crafts: int = 0      # crafts restants dans le lot
var output_stock: Dictionary = {}
var timer: float = 0.0

var selected_recipe: Recipe = null   # recette choisie dans l'UI
var input_stock: Dictionary = {}     # item_id -> {"item": Item, "amount": int} (alimenté par les exporteurs)
var infinite_mode: bool = false

const MAX_BATCH := 99
const BAR_WIDTH := 32.0
const BAR_HEIGHT := 5.0
const BAR_OFFSET := Vector2(-BAR_WIDTH / 2.0, 38.0)

const IndicatorFont := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const INDICATOR_ICON_SIZE := Vector2(16, 16)
const INDICATOR_OFFSET := Vector2(-20, 40)   # sous le bâtiment, ajuste si besoin

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

# --- Ingrédients ---
# Stock d'entrée (restes du mode infini) + inventaire
func get_available(item: Item) -> int:
	var in_stock: int = input_stock[item.id]["amount"] if input_stock.has(item.id) else 0
	return in_stock + Inventory.get_item_amount(item)

# Consomme d'abord le stock d'entrée, puis l'inventaire
func _consume_ingredient(item: Item, amount: int) -> void:
	var from_stock := 0
	if input_stock.has(item.id):
		from_stock = mini(amount, input_stock[item.id]["amount"])
		input_stock[item.id]["amount"] -= from_stock
		if input_stock[item.id]["amount"] <= 0:
			input_stock.erase(item.id)
	var rest := amount - from_stock
	if rest > 0:
		Inventory.remove_item(item, rest)

# --- Mode manuel ---
# Nombre max de crafts possibles avec ce qu'on a
func get_max_craftable(recipe: Recipe) -> int:
	if recipe == null or not recipe.is_unlocked():
		return 0

	var result := MAX_BATCH
	for i in recipe.input_items.size():
		var needed: int = recipe.input_amounts[i]
		if needed <= 0:
			continue
		var have := get_available(recipe.input_items[i])
		result = mini(result, int(have / float(needed)))

	# Un upgrade ne se craft qu'une fois, et pas s'il attend d'être collecté
	if recipe.output_item is UpgradeItem:
		if output_stock.has(recipe.output_item.id):
			return 0
		result = mini(result, 1)

	return maxi(result, 0)

# Lance un lot manuel : prélève les ingrédients
func start_batch(recipe: Recipe, count: int) -> bool:
	if infinite_mode or is_busy() or recipe == null:
		return false
	if count <= 0 or count > get_max_craftable(recipe):
		return false

	for i in recipe.input_items.size():
		_consume_ingredient(recipe.input_items[i], recipe.input_amounts[i] * count)

	selected_recipe = recipe
	active_recipe = recipe
	remaining_crafts = count
	timer = 0.0
	return true

# Changement de recette (impossible pendant un craft ou en mode infini)
func select_recipe(recipe: Recipe) -> void:
	if infinite_mode or is_busy():
		return
	selected_recipe = recipe

# --- Mode infini ---
# À modifier si le déblocage doit dépendre d'autre chose
func can_use_infinite_mode() -> bool:
	return StorageNetwork.is_active()

func start_infinite() -> bool:
	if not can_use_infinite_mode() or is_busy():
		return false
	if selected_recipe == null or not selected_recipe.is_unlocked():
		return false
	infinite_mode = true
	return true

func stop_infinite() -> void:
	infinite_mode = false
	_return_stock()

# Renvoie au réseau le stock d'entrée (ce qui ne passe pas reste dans la machine)
func _return_stock() -> void:
	for id in input_stock.keys():
		var entry = input_stock[id]
		var returned := StorageNetwork.add_item(entry["item"], entry["amount"])
		entry["amount"] -= returned
		if entry["amount"] <= 0:
			input_stock.erase(id)

# Quantité d'un item nécessaire pour UN craft de la recette sélectionnée
func _amount_per_craft(item: Item) -> int:
	if selected_recipe == null:
		return 0
	var total := 0
	for i in selected_recipe.input_items.size():
		var input = selected_recipe.input_items[i]
		if input != null and input.id == item.id:
			total += selected_recipe.input_amounts[i]
	return total

# Appelé par les exporteurs : uniquement en mode infini, jamais plus d'un craft d'avance
func accept_input(item: Item, amount: int) -> int:
	if is_ghost or not infinite_mode:
		return 0
	var per_craft := _amount_per_craft(item)
	if per_craft <= 0:
		return 0
	var have: int = input_stock[item.id]["amount"] if input_stock.has(item.id) else 0
	var to_add := mini(amount, per_craft - have)
	if to_add <= 0:
		return 0
	if input_stock.has(item.id):
		input_stock[item.id]["amount"] += to_add
	else:
		input_stock[item.id] = {"item": item, "amount": to_add}
	return to_add

func _can_start_cycle(recipe: Recipe) -> bool:
	if not recipe.is_unlocked():
		return false
	if recipe.output_item is UpgradeItem and output_stock.has(recipe.output_item.id):
		return false
	for i in recipe.input_items.size():
		var item: Item = recipe.input_items[i]
		var have: int = input_stock[item.id]["amount"] if input_stock.has(item.id) else 0
		if have < recipe.input_amounts[i]:
			return false
	return true

func _try_start_cycle() -> void:
	var recipe := selected_recipe
	if recipe == null or not _can_start_cycle(recipe):
		return
	# Le stock suffit (vérifié ci-dessus) : l'inventaire n'est jamais touché
	for i in recipe.input_items.size():
		_consume_ingredient(recipe.input_items[i], recipe.input_amounts[i])
	active_recipe = recipe
	remaining_crafts = 1
	timer = 0.0

# --- Production ---
func _process(delta: float) -> void:
	if is_ghost:
		return

	if remaining_crafts > 0 and active_recipe != null:
		timer += delta
		if timer >= active_recipe.production_time:
			timer = 0.0
			_craft_once()

	# Mode infini : dès qu'un craft est fini, on enchaîne si le stock le permet
	if infinite_mode and remaining_crafts <= 0:
		_try_start_cycle()

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

	# Barre de progression
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
	if infinite_mode:
		text = "∞"
	draw_string(IndicatorFont, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, 0.6))
	draw_string(IndicatorFont, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f5a623"))

# --- Sortie ---
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

# Appelé par les importeurs adjacents
func export_output(importer: Node) -> void:
	for id in output_stock.keys():
		var entry = output_stock[id]
		if not importer.accepts(entry["item"]):
			continue
		var added := StorageNetwork.add_item(entry["item"], entry["amount"])
		if added <= 0:
			continue
		entry["amount"] -= added
		if entry["amount"] <= 0:
			output_stock.erase(id)
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

# --- Sauvegarde ---
func _stock_to_array(stock: Dictionary) -> Array:
	var result: Array = []
	for id in stock:
		result.append({"item_path": stock[id]["item"].resource_path, "amount": stock[id]["amount"]})
	return result

func _array_to_stock(data: Array) -> Dictionary:
	var stock := {}
	for entry in data:
		var item: Item = load(entry["item_path"])
		if item != null:
			stock[item.id] = {"item": item, "amount": int(entry["amount"])}
	return stock

func save_state() -> Dictionary:
	return {
		"input": _stock_to_array(input_stock),
		"output": _stock_to_array(output_stock),
		"selected": selected_recipe.resource_path if selected_recipe != null else "",
		"recipe": active_recipe.resource_path if active_recipe != null else "",
		"remaining": remaining_crafts,
		"timer": timer,
		"infinite": infinite_mode
	}

func load_state(data: Dictionary) -> void:
	input_stock = _array_to_stock(data.get("input", []))
	output_stock = _array_to_stock(data.get("output", []))
	infinite_mode = bool(data.get("infinite", false))

	var selected_path: String = data.get("selected", "")
	selected_recipe = load(selected_path) as Recipe if selected_path != "" else null

	active_recipe = null
	remaining_crafts = 0
	timer = 0.0
	var recipe_path: String = data.get("recipe", "")
	if recipe_path != "":
		active_recipe = load(recipe_path) as Recipe
		if active_recipe != null:
			remaining_crafts = int(data.get("remaining", 0))
			timer = float(data.get("timer", 0.0))

	_update_output_label()
