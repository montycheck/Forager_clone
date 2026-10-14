extends Node2D

var is_ghost: bool = false

func set_ghost(value: bool) -> void:
	is_ghost = value

func _ready() -> void:
	if is_ghost:
		return
	add_to_group("persist")
	StorageNetwork.register_core(self)

func _exit_tree() -> void:
	StorageNetwork.unregister_core(self)
