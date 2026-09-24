extends PanelContainer

signal skill_clicked(skill: Skill)

@export var skill: Skill

@onready var icon: TextureRect = $Content/Icon
@onready var name_label: Label = $Content/NameLabel

var style_locked: StyleBoxFlat
var style_available: StyleBoxFlat
var style_unlocked: StyleBoxFlat

func _ready() -> void:
	_build_styles()

	gui_input.connect(_on_gui_input)
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size / 2
	resized.connect(func(): pivot_offset = size / 2)

	if skill != null:
		icon.texture = skill.icon
		name_label.text = skill.display_name

	refresh()

func _build_styles() -> void:
	style_locked = StyleBoxFlat.new()
	style_locked.bg_color = Color("#26262c")
	style_locked.set_corner_radius_all(10)
	style_locked.set_border_width_all(2)
	style_locked.border_color = Color("#3a3a42")

	style_available = StyleBoxFlat.new()
	style_available.bg_color = Color("#2e2e38")
	style_available.set_corner_radius_all(10)
	style_available.set_border_width_all(2)
	style_available.border_color = Color("#f5a623")

	style_unlocked = StyleBoxFlat.new()
	style_unlocked.bg_color = Color("#2e2e38")
	style_unlocked.set_corner_radius_all(10)
	style_unlocked.set_border_width_all(2)
	style_unlocked.border_color = Color("#5fd068")

func refresh() -> void:
	if skill == null:
		return

	if PlayerProgress.is_skill_unlocked(skill.id):
		add_theme_stylebox_override("panel", style_unlocked)
		icon.modulate = Color(1, 1, 1, 1)
		return

	var prereq_ok := skill.required_skill_id == "" or PlayerProgress.is_skill_unlocked(skill.required_skill_id)
	var can_afford := PlayerProgress.skill_points > 0

	if prereq_ok and can_afford:
		add_theme_stylebox_override("panel", style_available)
		icon.modulate = Color(1, 1, 1, 1)
	else:
		add_theme_stylebox_override("panel", style_locked)
		icon.modulate = Color(1, 1, 1, 0.4)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_play_pop()
		skill_clicked.emit(skill)

func _play_pop() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
