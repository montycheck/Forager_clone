extends Control

const RecipeOptionScene := preload("res://scenes/ui/station_recipe_option.tscn")
const IngredientBadgeScene := preload("res://scenes/ui/ingredient_badge.tscn")
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

var viewed_recipe: Recipe = null   # recette affichée / sélectionnée
var craft_count: int = 1
var was_busy: bool = false

var quantity_row: HBoxContainer
var count_label: Label
var start_button: Button

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	collect_button.pressed.connect(_on_collect_pressed)
	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	Inventory.inventory_changed.connect(_on_inventory_changed)
	_build_extra_controls()
	visible = false

# --- Contrôles créés par script (pas de modif du .tscn) ---
func _build_extra_controls() -> void:
	var root := ingredients_list.get_parent()
	var idx := ingredients_list.get_index()

	quantity_row = HBoxContainer.new()
	root.add_child(quantity_row)
	root.move_child(quantity_row, idx + 1)

	_add_row_button("-", func(): _set_count(craft_count - 1))
	count_label = Label.new()
	count_label.custom_minimum_size = Vector2(70, 0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_row.add_child(count_label)
	_add_row_button("+", func(): _set_count(craft_count + 1))
	_add_row_button("1", func(): _set_count(1))
	_add_row_button("½", func(): _set_count(int(_get_max() / 2.0)))
	_add_row_button("Max", func(): _set_count(_get_max()))

	start_button = Button.new()
	start_button.text = "Lancer"
	start_button.pressed.connect(_on_start_pressed)
	root.add_child(start_button)
	root.move_child(start_button, idx + 2)

func _add_row_button(text: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	quantity_row.add_child(b)

# --- Logique ---
func _get_max() -> int:
	if current_station == null or viewed_recipe == null:
		return 0
	return current_station.get_max_craftable(viewed_recipe)

func _set_count(value: int) -> void:
	if current_station == null or current_station.is_busy():
		return
	craft_count = clampi(value, 1, maxi(1, _get_max()))
	_rebuild_ingredients()

func _on_inventory_changed() -> void:
	if visible and current_station != null and not current_station.is_busy():
		_set_count(craft_count)

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
	if current_station.is_busy():
		return
	viewed_recipe = recipe
	craft_count = 1
	_set_count(1)

func _rebuild_ingredients() -> void:
	for child in ingredients_list.get_children():
		ingredients_list.remove_child(child)
		child.queue_free()

	if viewed_recipe == null:
		return

	for i in viewed_recipe.input_items.size():
		var badge := IngredientBadgeScene.instantiate()
		ingredients_list.add_child(badge)
		badge.set_data(viewed_recipe.input_items[i], viewed_recipe.input_amounts[i] * craft_count)

func _process(_delta: float) -> void:
	if visible and current_station != null:
		_refresh_state()

func _refresh_state() -> void:
	var busy: bool = current_station.is_busy()

	if busy:
		viewed_recipe = current_station.active_recipe
	elif was_busy:
		_set_count(craft_count)   # lot fini : on remet à jour l'affichage
	was_busy = busy

	# Boutons de recettes : verrouillés pendant un lot
	for child in recipe_select_box.get_children():
		if child is Button and child.get("recipe") != null:
			child.disabled = busy or not child.recipe.is_unlocked()

	ingredients_list.visible = not busy and viewed_recipe != null
	quantity_row.visible = not busy and viewed_recipe != null
	start_button.visible = not busy
	progress_bar.visible = busy

	var max_count := _get_max()

	if busy:
		var recipe: Recipe = current_station.active_recipe
		progress_bar.value = clamp(current_station.timer / recipe.production_time, 0.0, 1.0) if recipe.production_time > 0.0 else 1.0
		status_label.text = "En production... %d restant(s)" % current_station.remaining_crafts
	elif viewed_recipe == null:
		status_label.text = "Choisis une recette ci-dessus."
	elif max_count <= 0:
		status_label.text = "Ingrédients insuffisants."
	else:
		status_label.text = "Prêt à lancer."

	if max_count > 0:
		count_label.text = "%d / %d" % [craft_count, max_count]
	else:
		count_label.text = "0"

	# Boutons de quantité inutiles tant qu'aucun craft n'est possible
	for child in quantity_row.get_children():
		if child is Button:
			child.disabled = max_count <= 0
	start_button.disabled = busy or viewed_recipe == null or max_count <= 0

	# Sortie : toujours collectable
	var total: int = current_station.get_output_total()
	output_amount_label.text = str(total)
	var first: Item = current_station.get_first_output_item()
	output_icon.texture = first.icon if first != null else null
	collect_button.disabled = total <= 0

func _on_start_pressed() -> void:
	if current_station.start_batch(viewed_recipe, craft_count):
		_refresh_state()

func _on_collect_pressed() -> void:
	current_station.collect_output()

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "crafting_station":
		current_station = pending_station
		title_label.text = current_station.station_display_name

		for child in recipe_select_box.get_children():
			recipe_select_box.remove_child(child)
			child.queue_free()

		for recipe in _load_recipes_for(current_station.building_id):
			var option := RecipeOptionScene.instantiate()
			recipe_select_box.add_child(option)
			option.set_data(recipe)
			option.recipe_selected.connect(_on_recipe_selected)

		viewed_recipe = current_station.active_recipe if current_station.is_busy() else null
		was_busy = current_station.is_busy()
		craft_count = 1
		_rebuild_ingredients()
		_refresh_state()
		UITransitions.show_panel(self)

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "crafting_station":
		current_station = null
		UITransitions.hide_panel(self)

func _on_close_pressed() -> void:
	UIManager.close_menu()
