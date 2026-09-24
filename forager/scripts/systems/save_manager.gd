extends Node

const SAVE_DIR := "C:/Users/inter/Documents/DEV/gd/forager/saves"
const SAVE_PATH := SAVE_DIR + "/savegame.json"

var pending_load: bool = false
var current_seed: int = 0

func save_game():
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {}
	
	data["inventory"] = Inventory.save_data()
	data["progress"] = PlayerProgress.save_data()
	data["world_seed"] = current_seed
	
	var player := get_tree().get_first_node_in_group("player")
	data["player"] = player.save_data()
	
	var objects: Array = []
	for node in get_tree().get_nodes_in_group("persist"):
		objects.append({
			"scene_path": node.scene_file_path,
			"pos_x": node.global_position.x,
			"pos_y": node.global_position.y
		})
	data["objects"] = objects
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	print("Game Saved")

func get_save_seed():
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null or not data.has("world_seed"):
		return 0
	current_seed = data["world_seed"]
	return current_seed

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save found")
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(text)
	if data == null:
		print("Error reading save")
		return
		
	Inventory.load_data(data["inventory"])
	PlayerProgress.load_data(data["progress"])
	
	var player := get_tree().get_first_node_in_group("player")
	player.load_data(data["player"])
	
	for node in get_tree().get_nodes_in_group("persist"):
		node.queue_free()
		
	for entry in data["objects"]:
		var scene: PackedScene = load(entry["scene_path"])
		var instance := scene.instantiate()
		get_tree().get_first_node_in_group("y_sort_root").add_child(instance)
		instance.global_position = Vector2(entry["pos_x"], entry["pos_y"])
		
	print("Game loaded")

func has_save_file():
	return FileAccess.file_exists(SAVE_PATH)
	
func request_load_game():
	pending_load = true
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func request_new_game():
	pending_load = false
	current_seed = randi()
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")
