extends Control

@onready var bar: ProgressBar = $Bar
@onready var level_label: Label = $LevelLabel

func _ready() -> void:
	PlayerProgress.xp_changed.connect(_update_display)
	PlayerProgress.level_up.connect(_on_level_up)
	_update_display()

func _update_display():
	bar.value = PlayerProgress.get_xp_progress()
	level_label.text = "Level %d" % PlayerProgress.current_level
	
func _on_level_up(new_level: int):
	print("Level up : Level %d" % new_level)
