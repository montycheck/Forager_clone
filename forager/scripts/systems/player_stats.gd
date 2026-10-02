extends Node

signal upgrades_changed

var upgrades: Dictionary = {}

func get_tier(line_id: String):
	return upgrades[line_id].tier if upgrades.has(line_id) else 0

func acquire(upgrade: UpgradeItem):
	if upgrade.tier <= get_tier(upgrade.line_id):
		return false
	upgrades[upgrade.line_id] = upgrade
	upgrades_changed.emit()
	return true
	
func get_value(stat: int, base: float = 1.0):
	var add := 0.0
	var mult := 1.0
	for upgrade in upgrades.values():
		for mod in upgrade.effects:
			if mod.stat != stat:
				continue
			if mod.mode == StatModifier.Mode.ADD:
				add += mod.value
			else:
				mult *= mod.value
	return (base + add) * mult

func get_hit_power() -> int:
	return maxi(1, int(round(get_value(StatModifier.Stat.HIT_POWER, 1.0))))

func save_data() -> Dictionary:
	var result := {}
	for line_id in upgrades:
		result[line_id] = upgrades[line_id].resource_path
	return result

func load_data(data: Dictionary) -> void:
	upgrades.clear()
	for line_id in data:
		upgrades[line_id] = load(data[line_id])
	upgrades_changed.emit()
