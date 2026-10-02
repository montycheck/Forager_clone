extends Resource
class_name StatModifier

enum Stat { HARVEST_SPEED, MOVE_SPEED, HIT_POWER}
enum Mode { ADD, MULTIPLY}

@export var stat: Stat = Stat.HARVEST_SPEED
@export var mode: Mode = Mode.ADD
@export var value: float = 0.1

const STAT_NAMES := {
	Stat.HARVEST_SPEED: "Harvesting speed",
	Stat.MOVE_SPEED: "Movement speed",
	Stat.HIT_POWER: "Strengh",
}

func describe() -> String:
	var label: String = STAT_NAMES[stat]
	if mode == Mode.MULTIPLY:
		return "%s x%.2f" % [label, value]
	if stat == Stat.HIT_POWER:
		return "%s +%d" % [label, int(value)]
	return "%s +%d%%" % [label, int(round(value * 100.0))]
