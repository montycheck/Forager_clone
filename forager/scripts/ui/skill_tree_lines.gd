extends Control

var lines : Array = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func set_lines(new_lines: Array):
	lines = new_lines
	queue_redraw()
	
func _draw() -> void:
	for line in lines:
		draw_line(line["from"], line["to"], Color("#44444e"), 2.0)
		
