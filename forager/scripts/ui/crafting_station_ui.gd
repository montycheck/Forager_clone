extends Control

const RecipeOptionScene := preload("res://scenes/ui/station_recipe_option.tscn")
const IngredientRowScene := preload("res://scenes/ui/ingredient_deposit_row.tscn")
const RECIPES_FOLDER := "res://resources/recipes/"

@onready var title_label: Label = $Panel/Root/TopBar/TitleLabel
@onready var close_button: Button = $Panel/Root/TopBar/CloseButton
@onready var recipe_select_box: HBoxContainer = $Panel/Root/RecipeSelectBox
@onready var ingredients_list: VBoxContainer = $Panel/Root/IngredientsList
@onready var progress_bar: ProgressBar = $Panel/Root/ProductionProgress
@onready var status_label: Label = $Panel/Root/StatusLabel
@onready var output_icon: TextureRect = $Panel/Root/OutputBox/OutputIcon
@onready var output_amount_label: Label = $Panel/Root/OutputBox/OutputAmountLabel
@onready var collect_button: Button = $Panel/Root/OutputBox/CollectButton

var pending_station: Node2D = null
var current_station: Node2D = null

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	collect_button.pressed.connect(_on_collect_pressed)
	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	visible = false

func _process(_delta: float) -> void:
	if visible and current_station != null:
		_refresh_content()

func open_for_station(station: Node2D) -> void:
	pending_station = station
	UIManager.open_menu("crafting_station")

func _load_recipes_for(building_id: String) -> Array[Recipe]:
	var recipes: Array[Recipe] = []

	var dir := DirAccess.open(RECIPES_FOLDER)
	if dir == null:
		return recipes

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(RECIPES_FOLDER + file_name)
			if resource is Recipe and resource.required_building_id == building_id:
				recipes.append(resource)
		file_name = dir.get_next()

	dir.list_dir_end()
	return recipes

func _on_recipe_selected(recipe: Recipe) -> void:
	current_station.set_recipe(recipe)
	_refresh_content()

func _refresh_content() -> void:
	var recipe: Recipe = current_station.selected_recipe

	_refresh_ingredient_rows(recipe)

	if recipe == null:
		status_label.text = "Choisis une recette ci-dessus."
		progress_bar.visible = false
	else:
		progress_bar.visible = true
		var progress := 0.0
		if recipe.production_time > 0.0:
			progress = clamp(current_station.timer / recipe.production_time, 0.0, 1.0)
		progress_bar.value = progress

		if _station_has_enough():
			status_label.text = "En production..."
		else:
			status_label.text = "En attente d'ingrédients."

		output_icon.texture = recipe.output_item.icon

	var output_total = current_station.get_output_total()
	output_amount_label.text = str(output_total)
	collect_button.disabled = output_total <= 0

func _refresh_ingredient_rows(recipe: Recipe) -> void:
	var existing_ids: Array = []
	for child in ingredients_list.get_children():
		existing_ids.append(child.item.id)

	var needed_ids: Array = []
	if recipe != null:
		for item in recipe.input_items:
			needed_ids.append(item.id)

	if existing_ids != needed_ids:
		for child in ingredients_list.get_children():
			child.queue_free()

		if recipe != null:
			for i in recipe.input_items.size():
				var row := IngredientRowScene.instantiate()
				ingredients_list.add_child(row)
				row.set_data(recipe.input_items[i], recipe.input_amounts[i], current_station)
	else:
		for child in ingredients_list.get_children():
			child.refresh()

func _station_has_enough() -> bool:
	var recipe: Recipe = current_station.selected_recipe
	if recipe == null:
		return false
	for i in recipe.input_items.size():
		if current_station.get_input_amount(recipe.input_items[i]) < recipe.input_amounts[i]:
			return false
	return true

func _on_collect_pressed() -> void:
	current_station.collect_output()
	_refresh_content()

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "crafting_station":
		current_station = pending_station
		title_label.text = current_station.station_display_name

		for child in recipe_select_box.get_children():
			child.queue_free()

		for recipe in _load_recipes_for(current_station.building_id):
			var option := RecipeOptionScene.instantiate()
			recipe_select_box.add_child(option)
			option.set_data(recipe)
			option.recipe_selected.connect(_on_recipe_selected)

		_refresh_content()
		UITransitions.show_panel(self)

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "crafting_station":
		current_station = null
		UITransitions.hide_panel(self)

func _on_close_pressed() -> void:
	UIManager.close_menu()
