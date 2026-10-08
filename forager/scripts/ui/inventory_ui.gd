extends Control

const SlotScene := preload("res://scenes/ui/inventory_slot.tscn")

@onready var slots_container: HBoxContainer = $SlotsContainer

func _ready() -> void:
	Inventory.inventory_changed.connect(_on_inventory_changed)
	_on_inventory_changed()
	
func _on_inventory_changed():
	for child in slots_container.get_children():
		child.queue_free()

	for i in Inventory.slots.size():
		var slot_data = Inventory.slots[i]
		var slot_ui := SlotScene.instantiate()
		slot_ui.slot_index = i
		slots_container.add_child(slot_ui)
		slot_ui.set_slot_data(slot_data["item"], slot_data["amount"])
