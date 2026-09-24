extends Control

const SkillNodeScene := preload("res://scenes/ui/skill_node.tscn")
const SKILLS_FOLDER := "res://resources/skills/"

@onready var points_label: Label = $Panel/Root/Content/PointsLabel
@onready var skills_grid: GridContainer = $Panel/Root/Content/SkillsGrid
@onready var close_button: Button = $Panel/Root/TopBar/CloseButton

func _ready() -> void:
	$Panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	$Panel.offset_left = 60
	$Panel.offset_top = 60
	$Panel.offset_right = -60
	$Panel.offset_bottom = -60

	close_button.pressed.connect(_on_close_pressed)
	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	visible = false

	for skill in _load_all_skills():
		var node := SkillNodeScene.instantiate()
		node.skill = skill
		skills_grid.add_child(node)
		node.skill_clicked.connect(_on_skill_clicked)

	_update_display()

func _load_all_skills() -> Array[Skill]:
	var skills: Array[Skill] = []

	var dir := DirAccess.open(SKILLS_FOLDER)
	if dir == null:
		push_error("Impossible d'ouvrir le dossier : " + SKILLS_FOLDER)
		return skills

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(SKILLS_FOLDER + file_name)
			if resource is Skill:
				skills.append(resource)
		file_name = dir.get_next()

	dir.list_dir_end()
	return skills

func _update_display() -> void:
	points_label.text = "Points de compétence : %d" % PlayerProgress.skill_points

	for node in skills_grid.get_children():
		node.refresh()

func _on_skill_clicked(skill: Skill) -> void:
	if PlayerProgress.unlock_skill(skill.id):
		_update_display()

func toggle() -> void:
	UIManager.open_menu("skill")

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "skill":
		UITransitions.show_panel(self)
		_update_display()

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "skill":
		UITransitions.hide_panel(self)

func _on_close_pressed() -> void:
	UIManager.close_menu()
