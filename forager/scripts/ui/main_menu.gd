extends Control

@onready var new_game_button: Button = $Panel/Buttons/NewGameButton
@onready var load_game_button: Button = $Panel/Buttons/LoadGameButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	
	load_game_button.disabled = not SaveManager.has_save_file()
	
func _on_new_game_pressed():
	SaveManager.request_new_game()
	
func _on_load_game_pressed():
	SaveManager.request_load_game()
