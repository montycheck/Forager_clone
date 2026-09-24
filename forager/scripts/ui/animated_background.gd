extends ColorRect

@export var color_a: Color = Color("#1a1a2e")
@export var color_b: Color = Color("#16213e")
@export var cycle_duration: float = 6.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	color = color_a
	_start_cycle()

func _start_cycle() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(self, "color", color_b, cycle_duration)
	tween.tween_property(self, "color", color_a, cycle_duration)
