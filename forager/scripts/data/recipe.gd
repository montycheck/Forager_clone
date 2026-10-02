extends Resource
class_name Recipe

@export var output_item: Item
@export var output_amount: int = 1

@export var input_items: Array[Item] = []
@export var input_amounts: Array[int] = []

@export var required_skill_id: String = ""
@export var required_stage_id: String = ""
@export var required_building_id: String = ""
@export var production_time: float = 3.0

func is_unlocked() -> bool:
	if required_skill_id != "" and not PlayerProgress.is_skill_unlocked(required_skill_id):
		return false
	if required_stage_id != "" and not PlayerProgress.is_stage_validated(required_stage_id):
		return false
	if output_item is UpgradeItem and not output_item.can_acquire():
		return false
	return true
