extends Button

signal recipe_selected(recipe: Recipe)

var recipe: Recipe

func set_data(p_recipe: Recipe) -> void:
	recipe = p_recipe
	icon = recipe.output_item.icon
	disabled = not recipe.is_unlocked()
	if recipe.output_item is UpgradeItem:
		tooltip_text = recipe.output_item.get_description()
	else:
		tooltip_text = recipe.output_item.display_name
	pressed.connect(func(): recipe_selected.emit(recipe))
