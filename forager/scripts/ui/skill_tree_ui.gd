extends Control

const SkillNodeScene := preload("res://scenes/ui/skill_node.tscn")
const SKILLS_FOLDER := "res://resources/skills/"
const CELL_SIZE := Vector2(120, 120)
const NODE_SIZE := Vector2(90, 90)

@onready var points_label: Label = $Panel/Root/Content/PointsLabel
@onready var skills_canvas: Control = $Panel/Root/Content/SkillsScroll/SkillsCanvas
@onready var tree_lines: Control = $Panel/Root/Content/SkillsScroll/SkillsCanvas/TreeLines
@onready var close_button: Button = $Panel/Root/TopBar/CloseButton

var skill_nodes: Dictionary = {}

func _ready() -> void:
	$Panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	$Panel.offset_left = 60
	$Panel.offset_top = 60
	$Panel.offset_right = -60
	$Panel.offset_bottom = -60

	var content: VBoxContainer = $Panel/Root/Content
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll: ScrollContainer = $Panel/Root/Content/SkillsScroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	close_button.pressed.connect(_on_close_pressed)
	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	visible = false

	_build_tree()
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

func _build_tree() -> void:
	var skills := _load_all_skills()

	var max_col := 0
	var max_row := 0

	for skill in skills:
		max_col = max(max_col, skill.tree_position.x)
		max_row = max(max_row, skill.tree_position.y)

	var canvas_size := Vector2(max_col + 1, max_row + 1) * CELL_SIZE
	skills_canvas.custom_minimum_size = canvas_size
	skills_canvas.size = canvas_size

	for skill in skills:
		var node := SkillNodeScene.instantiate()
		node.skill = skill
		skills_canvas.add_child(node)
		node.position = Vector2(skill.tree_position) * CELL_SIZE
		node.size = NODE_SIZE
		node.skill_clicked.connect(_on_skill_clicked)
		skill_nodes[skill.id] = node

func _update_display() -> void:
	points_label.text = "Points de compétence : %d" % PlayerProgress.skill_points

	for node in skill_nodes.values():
		node.refresh()

	_update_lines()

func _update_lines() -> void:
	var lines: Array = []

	for id in skill_nodes:
		var node = skill_nodes[id]
		if not node.visible:
			continue

		var skill: Skill = node.skill
		if skill.required_skill_id != "" and skill_nodes.has(skill.required_skill_id):
			var parent_node = skill_nodes[skill.required_skill_id]
			if parent_node.visible:
				lines.append({
					"from": parent_node.position + NODE_SIZE / 2,
					"to": node.position + NODE_SIZE / 2
				})

	tree_lines.set_lines(lines)

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
