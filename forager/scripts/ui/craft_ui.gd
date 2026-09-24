extends Control

const RecipeEntryScene := preload("res://scenes/ui/recipe_entry.tscn")
const RECIPES_FOLDER := "res://resources/recipes/"

@onready var recipes_list: VBoxContainer = $Panel/Root/RecipesList
@onready var close_button: Button = $Panel/Root/TopBar/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	visible = false

	for recipe in _load_all_recipes():
		var entry := RecipeEntryScene.instantiate()
		entry.recipe = recipe
		recipes_list.add_child(entry)

func _load_all_recipes() -> Array[Recipe]:
	var recipes: Array[Recipe] = []

	var dir := DirAccess.open(RECIPES_FOLDER)
	if dir == null:
		push_error("Impossible d'ouvrir le dossier : " + RECIPES_FOLDER)
		return recipes

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(RECIPES_FOLDER + file_name)
			if resource is Recipe:
				recipes.append(resource)
		file_name = dir.get_next()

	dir.list_dir_end()
	return recipes

func toggle() -> void:
	UIManager.open_menu("craft")

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "craft":
		UITransitions.show_panel(self)

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "craft":
		UITransitions.hide_panel(self)

func _on_close_pressed() -> void:
	UIManager.close_menu()
