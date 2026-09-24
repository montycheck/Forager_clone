extends Node

signal inventory_changed

var slots: Array = []
var max_slots: int = 20

func add_item(item: Item, amount: int = 1) -> void:
	for slot in slots:
		if slot["item"].id == item.id and slot["amount"] < item.max_stack:
			slot["amount"] += amount
			inventory_changed.emit()
			return

	if slots.size() < max_slots:
		slots.append({"item": item, "amount": amount})
		inventory_changed.emit()
	else:
		print("Inventaire plein !")

func get_item_amount(item: Item) -> int:
	var total := 0
	for slot in slots:
		if slot["item"].id == item.id:
			total += slot["amount"]
	return total

func remove_item(item: Item, amount: int) -> void:
	var remaining := amount

	for slot in slots.duplicate():
		if slot["item"].id == item.id:
			var take: int = min(remaining, slot["amount"])
			slot["amount"] -= take
			remaining -= take

			if slot["amount"] <= 0:
				slots.erase(slot)

			if remaining <= 0:
				break

	inventory_changed.emit()

func has_items(items: Array[Item], amounts: Array[int]) -> bool:
	for i in items.size():
		if get_item_amount(items[i]) < amounts[i]:
			return false
	return true

func remove_items(items: Array[Item], amounts: Array[int]) -> void:
	for i in items.size():
		remove_item(items[i], amounts[i])

func has_ingredients(recipe: Recipe) -> bool:
	return has_items(recipe.input_items, recipe.input_amounts)

func craft(recipe: Recipe) -> bool:
	if not has_ingredients(recipe):
		return false

	remove_items(recipe.input_items, recipe.input_amounts)
	add_item(recipe.output_item, recipe.output_amount)
	PlayerProgress.add_xp(10)
	return true

func print_inventory() -> void:
	print("--- Inventaire ---")
	for slot in slots:
		print("%s x%d" % [slot["item"].display_name, slot["amount"]])
		
func save_data():
	var result: Array = []
	for slot in slots:
		result.append({
			"item_path": slot["item"].resource_path,
			"amount": slot["amount"]
		})
	return result
	
func load_data(data: Array):
	slots.clear()
	for entry in data:
		var item: Item = load(entry["item_path"])
		slots.append({"item": item, "amount": entry["amount"]})
	inventory_changed.emit()
