extends Control

var health_bar: ProgressBar
var hunger_bar: ProgressBar

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := VBoxContainer.new()
	box.position = Vector2(10, 80)   # sous l'XP et les upgrades, à ajuster
	box.add_theme_constant_override("separation", 4)
	add_child(box)

	health_bar = _make_bar(box, Color("#c0392b"))
	hunger_bar = _make_bar(box, Color("#f5a623"))
	_refresh()

func _process(delta: float) -> void:
	_refresh()

func _make_bar(parent: Control, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(180, 14)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#26262c")
	bg.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func _refresh() -> void:
	health_bar.max_value = PlayerVitals.max_health
	health_bar.value = PlayerVitals.health
	hunger_bar.max_value = PlayerVitals.max_hunger
	hunger_bar.value = PlayerVitals.hunger
