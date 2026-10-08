extends Control
class_name LoadingScreen

var bar: ProgressBar
var label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	var bg := ColorRect.new()
	bg.color = Color("#1a1a2e")
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(400,0)
	center.add_child(box)
	
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = "Loading..."
	box.add_child(label)
	
	bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0,16)
	bar.max_value = 1.0
	bar.show_percentage = false
	box.add_child(bar)

func set_progress(value: float, text: String = ""):
	bar.value = clampf(value, 0.0, 1.0)
	if text != "":
		label.text = text

func finish():
	bar.value = 1.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
