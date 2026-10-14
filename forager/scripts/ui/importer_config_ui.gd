extends Control

const ITEMS_FOLDER := "res://resources/items/"

var pending_importer: Node2D = null
var current_importer: Node2D = null
var checks: Dictionary = {}   # item_id -> CheckBox
var title_label: Label
var hint_label: Label

var list: VBoxContainer

func _ready() -> void:
	add_to_group("importer_config_ui")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()

	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)

func _build_ui() -> void:
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(380, 440)

	var root := VBoxContainer.new()
	panel.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	title_label = Label.new()
	title_label.text = "Importeur"
	top.add_child(title_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var close := Button.new()
	close.text = "X"
	close.pressed.connect(func(): UIManager.close_menu())
	top.add_child(close)

	hint_label = Label.new()
	root.add_child(hint_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 280)
	root.add_child(scroll)

	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for item in _load_all_items():
		var cb := CheckBox.new()
		cb.text = item.display_name
		cb.icon = item.icon
		cb.toggled.connect(_on_item_toggled.bind(item))
		list.add_child(cb)
		checks[item.id] = cb

	var clear_button := Button.new()
	clear_button.text = "Tout décocher"
	clear_button.pressed.connect(_on_clear_pressed)
	root.add_child(clear_button)

func _load_all_items() -> Array[Item]:
	var items: Array[Item] = []
	var dir := DirAccess.open(ITEMS_FOLDER)
	if dir == null:
		push_error("Impossible d'ouvrir le dossier : " + ITEMS_FOLDER)
		return items

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(ITEMS_FOLDER + file_name)
			if resource is Item and not resource is UpgradeItem:
				items.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()

	items.sort_custom(func(a, b): return a.display_name < b.display_name)
	return items

func open_for_importer(importer: Node2D) -> void:
	pending_importer = importer
	UIManager.open_menu("importer_config")

func _on_item_toggled(pressed: bool, item: Item) -> void:
	if current_importer != null:
		current_importer.set_allowed(item.id, pressed)

func _on_clear_pressed() -> void:
	if current_importer == null:
		return
	current_importer.clear_filter()
	for cb in checks.values():
		cb.set_pressed_no_signal(false)

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "importer_config":
		current_importer = pending_importer
		title_label.text = current_importer.get_config_title()
		hint_label.text = current_importer.get_config_hint()
		for id in checks:
			checks[id].set_pressed_no_signal(current_importer.is_allowed(id))
		UITransitions.show_panel(self)

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "importer_config":
		current_importer = null
		UITransitions.hide_panel(self)
