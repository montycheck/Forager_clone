extends Control

const BuildingCardScene := preload("res://scenes/ui/building_card.tscn")
const BUILDINGS_FOLDER := "res://resources/buildings/"

# Ordre d'affichage des onglets
const CATEGORY_NAMES := {
	Building.Category.MACHINES: "Machines",
	Building.Category.PASSIVE_PRODUCTION: "Production passive",
	Building.Category.STORAGE: "Stockage",
}

@onready var panel: PanelContainer = $Panel
@onready var root: VBoxContainer = $Panel/Root
@onready var buildings_list: VBoxContainer = $Panel/Root/BuildingsList
@onready var close_button: Button = $Panel/Root/TopBar/CloseButton

var cards: Array = []
var tab_buttons: Dictionary = {}   # catégorie -> Button
var current_category: int = Building.Category.MACHINES
var empty_label: Label
var style_tab_active: StyleBoxFlat

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	visible = false

	_build_layout()
	_build_cards()
	_select_category(current_category)

# --- Mise en page (onglets + liste scrollable), construite par script ---
func _build_layout() -> void:
	panel.custom_minimum_size = Vector2(560, 480)

	style_tab_active = StyleBoxFlat.new()
	style_tab_active.bg_color = Color("#5fd068")
	style_tab_active.set_corner_radius_all(10)
	style_tab_active.content_margin_left = 20
	style_tab_active.content_margin_right = 20
	style_tab_active.content_margin_top = 10
	style_tab_active.content_margin_bottom = 10

	# Onglets, juste au-dessus de la liste
	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	root.move_child(tabs, buildings_list.get_index())

	for category in CATEGORY_NAMES:
		var button := Button.new()
		button.text = CATEGORY_NAMES[category]
		button.pressed.connect(_select_category.bind(category))
		tabs.add_child(button)
		tab_buttons[category] = button

	# La liste existante passe dans un ScrollContainer
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	root.move_child(scroll, buildings_list.get_index())
	root.remove_child(buildings_list)
	scroll.add_child(buildings_list)
	buildings_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	empty_label = Label.new()
	empty_label.text = "Aucun bâtiment dans cette catégorie."
	buildings_list.add_child(empty_label)

func _build_cards() -> void:
	var buildings := _load_all_buildings()
	buildings.sort_custom(func(a, b): return a.display_name < b.display_name)

	for building in buildings:
		var card := BuildingCardScene.instantiate()
		card.building = building
		buildings_list.add_child(card)
		card.building_selected.connect(_on_building_selected)
		cards.append(card)

func _load_all_buildings() -> Array[Building]:
	var buildings: Array[Building] = []

	var dir := DirAccess.open(BUILDINGS_FOLDER)
	if dir == null:
		push_error("Impossible d'ouvrir le dossier : " + BUILDINGS_FOLDER)
		return buildings

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(BUILDINGS_FOLDER + file_name)
			if resource is Building:
				buildings.append(resource)
		file_name = dir.get_next()

	dir.list_dir_end()
	return buildings

# --- Catégories ---
func _select_category(category: int) -> void:
	current_category = category

	var any := false
	for card in cards:
		var matches: bool = card.building.category == category
		card.visible = matches
		if matches:
			any = true
	empty_label.visible = not any

	_update_tab_styles()

func _update_tab_styles() -> void:
	for category in tab_buttons:
		var button: Button = tab_buttons[category]
		if category == current_category:
			for state in ["normal", "hover", "pressed"]:
				button.add_theme_stylebox_override(state, style_tab_active)
			for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				button.add_theme_color_override(color_name, Color("#1a1a1a"))
		else:
			for state in ["normal", "hover", "pressed"]:
				button.remove_theme_stylebox_override(state)
			for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				button.remove_theme_color_override(color_name)

# --- Actions ---
func _on_building_selected(building: Building) -> void:
	UIManager.close_menu()
	BuildManager.start_placing(building)

func toggle() -> void:
	UIManager.open_menu("build_menu")

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "build_menu":
		UITransitions.show_panel(self)

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "build_menu":
		UITransitions.hide_panel(self)

func _on_close_pressed() -> void:
	UIManager.close_menu()
