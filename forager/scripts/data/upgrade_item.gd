extends Item
class_name UpgradeItem

@export var line_id: String = ""   # "gloves", "boots", "bracelet"...
@export var tier: int = 1
## Effets TOTAUX de ce tier (il remplace le précédent, il ne s'additionne pas)
@export var effects: Array[StatModifier] = []

func _init() -> void:
	max_stack = 1

func can_acquire() -> bool:
	return tier == PlayerStats.get_tier(line_id) + 1

func get_description() -> String:
	var lines: Array[String] = ["%s (Tier %d)" % [display_name, tier]]
	for e in effects:
		lines.append(e.describe())
	return "\n".join(lines)
