extends Node2D

@export var building_id: String = ""
@export var station_display_name: String = ""

@onready var output_label: Label = get_node_or_null("OutputLabel")

var is_ghost: bool = false
var selected_recipe: Recipe = null
var input_stock: Dictionary = {}
var output_stock: Dictionary = {}
var timer: float = 0.0

const BAR_WIDTH := 32.0
const BAR_HEIGHT := 5.0
const BAR_OFFSET := Vector2(-BAR_WIDTH / 2.0, -30.0)

func _ready() -> void:
	add_to_group("persist")
	_update_output_label()

func set_ghost(value: bool) -> void:
	is_ghost = value

func _process(delta: float) -> void:
	if is_ghost:
		return

	if selected_recipe != null and _has_enough_stock(selected_recipe):
		timer += delta
		if timer >= selected_recipe.production_time:
			timer = 0.0
			_craft_once()
	elif selected_recipe == null:
		timer = 0.0

	queue_redraw()

func _draw() -> void:
	if is_ghost or selected_recipe == null:
		return

	var progress := 0.0
	if selected_recipe.production_time > 0.0:
		progress = clamp(timer / selected_recipe.production_time, 0.0, 1.0)

	draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH, BAR_HEIGHT)), Color("#26262c"))
	draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH * progress, BAR_HEIGHT)), Color("#5fd068"))

func _has_enough_stock(recipe: Recipe) -> bool:
	for i in recipe.input_items.size():
		var id: String = recipe.input_items[i].id
		var needed: int = recipe.input_amounts[i]
		if not input_stock.has(id) or input_stock[id]["amount"] < needed:
			return false
	return true

func _craft_once() -> void:
	for i in selected_recipe.input_items.size():
		var id: String = selected_recipe.input_items[i].id
		input_stock[id]["amount"] -= selected_recipe.input_amounts[i]
		if input_stock[id]["amount"] <= 0:
			input_stock.erase(id)

	var out_item := selected_recipe.output_item
	if output_stock.has(out_item.id):
		output_stock[out_item.id]["amount"] += selected_recipe.output_amount
	else:
		output_stock[out_item.id] = {"item": out_item, "amount": selected_recipe.output_amount}

	_update_output_label()

func set_recipe(recipe: Recipe) -> void:
	selected_recipe = recipe
	timer = 0.0
	queue_redraw()

func get_input_amount(item: Item) -> int:
	if input_stock.has(item.id):
		return input_stock[item.id]["amount"]
	return 0

func deposit_item(item: Item, amount: int) -> void:
	var available := Inventory.get_item_amount(item)
	var to_deposit: int = min(amount, available)
	if to_deposit <= 0:
		return

	Inventory.remove_item(item, to_deposit)

	if input_stock.has(item.id):
		input_stock[item.id]["amount"] += to_deposit
	else:
		input_stock[item.id] = {"item": item, "amount": to_deposit}

func get_output_total() -> int:
	var total := 0
	for id in output_stock:
		total += output_stock[id]["amount"]
	return total

func collect_output() -> void:
	for id in output_stock.keys():
		var entry = output_stock[id]
		Inventory.add_item(entry["item"], entry["amount"])
	output_stock.clear()
	_update_output_label()

func _update_output_label() -> void:
	if output_label == null:
		return
	var total := get_output_total()
	output_label.text = str(total)
	output_label.visible = total > 0

func interact() -> void:
	var ui = get_tree().get_first_node_in_group("crafting_station_ui")
	ui.open_for_station(self)
