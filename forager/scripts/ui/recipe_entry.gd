extends PanelContainer

@export var recipe: Recipe

const IngredientBadgeScene := preload("res://scenes/ui/ingredient_badge.tscn")

@onready var output_icon: TextureRect = $Content/OutputIcon
@onready var name_label: Label = $Content/InfoBox/NameLabel
@onready var ingredients_box: HBoxContainer = $Content/InfoBox/IngredientsBox
@onready var craft_button: Button = $Content/CraftButton

func _ready() -> void:
	craft_button.pressed.connect(_on_craft_button_pressed)
	Inventory.inventory_changed.connect(_update_button_state)
	PlayerProgress.skill_points_changed.connect(_update_button_state)

	if recipe != null:
		output_icon.texture = recipe.output_item.icon
		name_label.text = recipe.output_item.display_name
		_build_ingredients_display()

	_update_button_state()

func _build_ingredients_display() -> void:
	for i in recipe.input_items.size():
		var badge := IngredientBadgeScene.instantiate()
		ingredients_box.add_child(badge)
		badge.set_data(recipe.input_items[i], recipe.input_amounts[i])

func _update_button_state() -> void:
	if recipe == null:
		return

	var skill_ok := recipe.required_skill_id == "" or PlayerProgress.is_skill_unlocked(recipe.required_skill_id)
	craft_button.disabled = not (Inventory.has_ingredients(recipe) and skill_ok)

func _on_craft_button_pressed() -> void:
	Inventory.craft(recipe)
