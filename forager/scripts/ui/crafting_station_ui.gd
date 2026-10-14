extends Control

const IngredientBadgeScene := preload("res://scenes/ui/ingredient_badge.tscn")
const RECIPES_FOLDER := "res://resources/recipes/"
const BATCH_SIZES := [1, 5, 10]

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

# Contrôles créés par script
var select_recipe_button: Button
var batch_row: HBoxContainer
var batch_buttons: Array[Button] = []
var infinite_button: Button
var stock_section: VBoxContainer
var stock_title: Label
var stock_box: HFlowContainer
var picker: PanelContainer
var picker_list: VBoxContainer

var _shown_recipe: Recipe = null
var _ingredients_dirty: bool = true
var _stock_signature: String = ""

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	collect_button.pressed.connect(_on_collect_pressed)
	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	_build_extra_controls()
	_build_picker()
	visible = false

# --- Construction de l'UI (par script, pas de modif du .tscn) ---
func _build_extra_controls() -> void:
	var root := ingredients_list.get_parent()

	# La liste des recettes n'est plus affichée directement
	recipe_select_box.visible = false

	select_recipe_button = Button.new()
	select_recipe_button.pressed.connect(_open_picker)
	root.add_child(select_recipe_button)
	root.move_child(select_recipe_button, recipe_select_box.get_index())

	var idx := ingredients_list.get_index()

	# x1 / x5 / x10
	batch_row = HBoxContainer.new()
	root.add_child(batch_row)
	root.move_child(batch_row, idx + 1)
	for n in BATCH_SIZES:
		var b := Button.new()
		b.text = "x%d" % n
		b.pressed.connect(_on_batch_pressed.bind(n))
		batch_row.add_child(b)
		batch_buttons.append(b)

	# Mode infini / Stop
	infinite_button = Button.new()
	infinite_button.pressed.connect(_on_infinite_pressed)
	root.add_child(infinite_button)
	root.move_child(infinite_button, idx + 2)

	# Stock d'entrée (items livrés par l'exporteur)
	stock_section = VBoxContainer.new()
	stock_section.add_theme_constant_override("separation", 4)
	root.add_child(stock_section)
	root.move_child(stock_section, idx + 3)

	stock_title = Label.new()
	stock_section.add_child(stock_title)

	stock_box = HFlowContainer.new()
	stock_section.add_child(stock_box)

# Panneau de choix de recette (par-dessus l'UI de la machine)
func _build_picker() -> void:
	picker = PanelContainer.new()
	add_child(picker)
	picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	picker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	picker.grow_vertical = Control.GROW_DIRECTION_BOTH
	picker.custom_minimum_size = Vector2(440, 320)
	picker.visible = false

	var box := VBoxContainer.new()
	picker.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)
	var title := Label.new()
	title.text = "Recettes disponibles"
	top.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var close := Button.new()
	close.text = "X"
	close.pressed.connect(_close_picker)
	top.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 240)
	box.add_child(scroll)

	picker_list = VBoxContainer.new()
	picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker_list.add_theme_constant_override("separation", 6)
	scroll.add_child(picker_list)

# --- Sélecteur de recette ---
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
			if resource is Recipe and resource.required_building_id == building_id and resource.output_item != null:
				recipes.append(resource)
		file_name = dir.get_next()

	dir.list_dir_end()

	recipes.sort_custom(func(a, b): return a.output_item.display_name < b.output_item.display_name)
	return recipes

func _open_picker() -> void:
	if current_station == null or current_station.is_busy() or current_station.infinite_mode:
		return

	for child in picker_list.get_children():
		picker_list.remove_child(child)
		child.queue_free()

	var any := false
	for recipe in _load_recipes_for(current_station.building_id):
		if not recipe.is_unlocked():
			continue
		any = true
		_add_recipe_row(recipe)

	if not any:
		var label := Label.new()
		label.text = "Aucune recette disponible."
		picker_list.add_child(label)

	picker.visible = true

func _close_picker() -> void:
	picker.visible = false

func _add_recipe_row(recipe: Recipe) -> void:
	var row := HBoxContainer.new()
	picker_list.add_child(row)   # dans l'arbre avant de remplir les badges

	var button := Button.new()
	button.icon = recipe.output_item.icon
	button.text = recipe.output_item.display_name
	button.custom_minimum_size = Vector2(170, 0)
	if recipe.output_item is UpgradeItem:
		button.tooltip_text = recipe.output_item.get_description()
	button.pressed.connect(_on_recipe_picked.bind(recipe))
	row.add_child(button)

	for i in recipe.input_items.size():
		if recipe.input_items[i] == null:
			continue
		var badge := IngredientBadgeScene.instantiate()
		row.add_child(badge)
		badge.set_data(recipe.input_items[i], recipe.input_amounts[i])

func _on_recipe_picked(recipe: Recipe) -> void:
	current_station.select_recipe(recipe)
	_close_picker()
	_refresh_state()

# --- Affichage ---
func _process(_delta: float) -> void:
	if visible and current_station != null:
		_refresh_state()

func _rebuild_ingredients(recipe: Recipe) -> void:
	_shown_recipe = recipe
	_ingredients_dirty = false

	for child in ingredients_list.get_children():
		ingredients_list.remove_child(child)
		child.queue_free()

	if recipe == null:
		return

	for i in recipe.input_items.size():
		if recipe.input_items[i] == null:
			continue
		var badge := IngredientBadgeScene.instantiate()
		ingredients_list.add_child(badge)
		badge.set_data(recipe.input_items[i], recipe.input_amounts[i])

func _refresh_stock_display() -> void:
	var stock: Dictionary = current_station.input_stock

	# On ne reconstruit que si le contenu a changé
	var signature := ""
	for id in stock:
		signature += "%s:%d;" % [id, stock[id]["amount"]]
	if signature == _stock_signature:
		return
	_stock_signature = signature

	for child in stock_box.get_children():
		stock_box.remove_child(child)
		child.queue_free()

	stock_title.text = "Stock de la machine" if not stock.is_empty() else "Stock de la machine : vide"

	for id in stock:
		var badge := IngredientBadgeScene.instantiate()
		stock_box.add_child(badge)
		badge.set_data(stock[id]["item"], stock[id]["amount"])

func _refresh_state() -> void:
	var station := current_station
	var busy: bool = station.is_busy()
	var infinite: bool = station.infinite_mode
	var recipe: Recipe = station.active_recipe if busy else station.selected_recipe

	if _ingredients_dirty or recipe != _shown_recipe:
		_rebuild_ingredients(recipe)

	# Bouton de sélection de recette
	if recipe != null:
		select_recipe_button.text = recipe.output_item.display_name
		select_recipe_button.icon = recipe.output_item.icon
	else:
		select_recipe_button.text = "Sélectionner la recette"
		select_recipe_button.icon = null
	select_recipe_button.disabled = busy or infinite

	ingredients_list.visible = recipe != null

	# Mode manuel : x1 / x5 / x10
	var max_count: int = station.get_max_craftable(station.selected_recipe)
	var manual_idle := not busy and not infinite
	batch_row.visible = manual_idle and recipe != null
	for i in batch_buttons.size():
		batch_buttons[i].disabled = max_count < BATCH_SIZES[i]

	# Mode infini / Stop
	infinite_button.visible = infinite or station.can_use_infinite_mode()
	infinite_button.text = "Stop" if infinite else "Mode infini"
	infinite_button.disabled = not infinite and (busy or station.selected_recipe == null or not station.selected_recipe.is_unlocked())

	# Stock d'entrée
	stock_section.visible = infinite or not station.input_stock.is_empty()
	_refresh_stock_display()

	# Progression et statut
	progress_bar.visible = busy
	if busy:
		progress_bar.value = clamp(station.timer / station.active_recipe.production_time, 0.0, 1.0) if station.active_recipe.production_time > 0.0 else 1.0
		if infinite:
			status_label.text = "Mode infini : en production..."
		else:
			status_label.text = "En production... %d restant(s)" % station.remaining_crafts
	elif infinite:
		status_label.text = "Mode infini : en attente d'ingrédients..."
	elif recipe == null:
		status_label.text = "Sélectionne une recette."
	elif max_count <= 0:
		status_label.text = "Ingrédients insuffisants."
	else:
		status_label.text = "Prêt à lancer."

	# Sortie : toujours collectable
	var total: int = station.get_output_total()
	output_amount_label.text = str(total)
	var first: Item = station.get_first_output_item()
	output_icon.texture = first.icon if first != null else null
	collect_button.disabled = total <= 0

# --- Actions ---
func open_for_station(station: Node2D) -> void:
	pending_station = station
	UIManager.open_menu("crafting_station")

func _on_batch_pressed(count: int) -> void:
	var recipe: Recipe = current_station.selected_recipe
	if recipe == null:
		return
	current_station.start_batch(recipe, count)
	_refresh_state()

func _on_infinite_pressed() -> void:
	if current_station.infinite_mode:
		current_station.stop_infinite()
	else:
		current_station.start_infinite()
	_refresh_state()

func _on_collect_pressed() -> void:
	current_station.collect_output()

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "crafting_station":
		current_station = pending_station
		title_label.text = current_station.station_display_name
		_ingredients_dirty = true
		_stock_signature = ""
		picker.visible = false
		_refresh_state()
		UITransitions.show_panel(self)

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "crafting_station":
		picker.visible = false
		current_station = null
		UITransitions.hide_panel(self)

func _on_close_pressed() -> void:
	UIManager.close_menu()
