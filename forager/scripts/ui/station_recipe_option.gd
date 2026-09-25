extends Button

signal recipe_selected(recipe: Recipe)

var recipe: Recipe

func set_data(p_recipe: Recipe) -> void:
	recipe = p_recipe
	icon = recipe.output_item.icon
	pressed.connect(func(): recipe_selected.emit(recipe))
