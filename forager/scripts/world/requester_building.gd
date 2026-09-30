extends Node2D

@export var biome_name: String = ""

const STAGES_FOLDER := "res://resources/progression_stages/"

var is_ghost: bool = false
var current_stage: ProgressionStage = null
var deposited_amount: int = 0

func _ready() -> void:
	add_to_group("persist")
	_load_current_stage()

func set_ghost(value: bool) -> void:
	is_ghost = value

func _load_current_stage() -> void:
	var stages := _load_all_stages_for_biome()
	stages.sort_custom(func(a, b): return a.stage_number < b.stage_number)

	current_stage = null
	deposited_amount = 0

	for stage in stages:
		if not PlayerProgress.is_stage_validated(stage.id):
			current_stage = stage
			break

func _load_all_stages_for_biome() -> Array[ProgressionStage]:
	var stages: Array[ProgressionStage] = []

	var dir := DirAccess.open(STAGES_FOLDER)
	if dir == null:
		return stages

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(STAGES_FOLDER + file_name)
			if resource is ProgressionStage and resource.biome_name == biome_name:
				stages.append(resource)
		file_name = dir.get_next()

	dir.list_dir_end()
	return stages

func get_input_amount(item: Item) -> int:
	if current_stage != null and item.id == current_stage.key_item.id:
		return deposited_amount
	return 0

func deposit_item(item: Item, amount: int) -> void:
	if current_stage == null or item.id != current_stage.key_item.id:
		return

	var available := Inventory.get_item_amount(item)
	var to_deposit: int = min(amount, available)
	if to_deposit <= 0:
		return

	Inventory.remove_item(item, to_deposit)
	deposited_amount += to_deposit

	if deposited_amount >= current_stage.key_item_amount:
		_complete_stage()

func _complete_stage() -> void:
	var completed_stage := current_stage

	PlayerProgress.add_xp(completed_stage.xp_reward)
	if completed_stage.reward_item != null:
		Inventory.add_item(completed_stage.reward_item, completed_stage.reward_amount)

	PlayerProgress.validate_stage(completed_stage.id)
	_load_current_stage()

func interact() -> void:
	var ui = get_tree().get_first_node_in_group("requester_ui")
	ui.open_for_requester(self)
