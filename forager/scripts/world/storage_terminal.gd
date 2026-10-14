extends Node2D

var is_ghost: bool = false

func set_ghost(value: bool) -> void:
	is_ghost = value

func _ready() -> void:
	if is_ghost:
		return
	add_to_group("persist")

func interact() -> void:
	if not StorageNetwork.is_active():
		return
	var ui = get_tree().get_first_node_in_group("storage_terminal_ui")
	if ui != null:
		ui.open()
