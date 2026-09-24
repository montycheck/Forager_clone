extends Button

func _ready() -> void:
	resized.connect(_update_pivot)
	_update_pivot()
	pressed.connect(_play_pop)
	
func _update_pivot():
	pivot_offset = size / 2
	
func _play_pop():
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
