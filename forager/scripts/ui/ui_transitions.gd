extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_panel(panel: Control) -> void:
	panel.visible = true
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size / 2

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_panel(panel: Control) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, 0.1)
	tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.1)
	tween.chain().tween_callback(func(): panel.visible = false)
