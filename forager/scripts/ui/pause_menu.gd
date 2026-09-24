extends Control

@onready var resume_button: Button = $Panel/Buttons/ResumeButton
@onready var save_button: Button = $Panel/Buttons/SaveButton
@onready var quit_button: Button = $Panel/Buttons/QuitButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
func toggle() -> void:
	if visible:
		UITransitions.hide_panel(self)
		get_tree().paused = false
	else:
		UITransitions.show_panel(self)
		get_tree().paused = true
	
func _on_resume_pressed():
	toggle()
	
func _on_save_pressed():
	SaveManager.save_game()
	
func _on_quit_pressed():
	get_tree().quit()
