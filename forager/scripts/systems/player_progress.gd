extends Node

signal xp_changed
signal level_up(new_level: int)
signal skill_points_changed

var current_xp: int = 0
var current_level: int = 1
var skill_points: int = 0

var unlocked_skills: Array[String] = []

const XP_PER_LEVEL: int = 100

func add_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit()

	while current_xp >= XP_PER_LEVEL:
		current_xp -= XP_PER_LEVEL
		current_level += 1
		skill_points += 1
		level_up.emit(current_level)
		skill_points_changed.emit()

	xp_changed.emit()

func get_xp_progress() -> float:
	return float(current_xp) / float(XP_PER_LEVEL)

func is_skill_unlocked(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id)

func unlock_skill(skill_id: String) -> bool:
	if is_skill_unlocked(skill_id):
		return false
	if skill_points <= 0:
		return false
	skill_points -= 1
	unlocked_skills.append(skill_id)
	skill_points_changed.emit()
	return true

func save_data():
	return {
		"xp": current_xp,
		"level": current_level,
		"skill_points": skill_points,
		"unlocked_skills": unlocked_skills
	}

func load_data(data: Dictionary):
	current_xp = data["xp"]
	current_level = data["level"]
	skill_points = data["skill_points"]
	unlocked_skills.clear()
	for skill_id in data["unlocked_skills"]:
		unlocked_skills.append(skill_id)
	xp_changed.emit()
	skill_points_changed.emit()
