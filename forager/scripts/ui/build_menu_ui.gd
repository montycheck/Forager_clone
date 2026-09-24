extends Control

const BuildingCardScene := preload("res://scenes/ui/building_card.tscn")
const BUILDINGS_FOLDER := "res://resources/buildings/"

@onready var buildings_list: VBoxContainer = $Panel/Root/BuildingsList
@onready var close_button: Button = $Panel/Root/TopBar/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	visible = false

	for building in _load_all_buildings():
		var card := BuildingCardScene.instantiate()
		card.building = building
		buildings_list.add_child(card)
		card.building_selected.connect(_on_building_selected)

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
