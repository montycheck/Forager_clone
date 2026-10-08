extends Item
class_name ConsumableItem

@export var hunger_restore: float = 0.0
@export var health_restore: float = 0.0

func can_use() -> bool:
	var useful_hunger := hunger_restore > 0.0 and PlayerVitals.hunger < PlayerVitals.max_hunger
	var useful_health := health_restore > 0.0 and PlayerVitals.health < PlayerVitals.max_health
	return useful_hunger or useful_health

func use() -> void:
	if hunger_restore > 0.0:
		PlayerVitals.restore_hunger(hunger_restore)
	if health_restore > 0.0:
		PlayerVitals.heal(health_restore)

func get_description() -> String:
	var lines: Array[String] = [display_name]
	if hunger_restore > 0.0:
		lines.append("Faim +%d" % int(hunger_restore))
	if health_restore > 0.0:
		lines.append("Vie +%d" % int(health_restore))
	return "\n".join(lines)
