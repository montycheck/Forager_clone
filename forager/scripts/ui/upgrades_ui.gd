extends Control

var row: HBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	row = HBoxContainer.new()
	row.position = Vector2(10, 40)   # sous la barre d'XP
	add_child(row)
	PlayerStats.upgrades_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in row.get_children():
		child.queue_free()
	for upgrade in PlayerStats.upgrades.values():
		var icon := TextureRect.new()
		icon.texture = upgrade.icon
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.tooltip_text = upgrade.get_description()
		row.add_child(icon)
