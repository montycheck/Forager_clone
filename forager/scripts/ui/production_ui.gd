extends Control

var pending_building: Node2D = null
var current_building: Node2D = null

var title_label: Label
var icon_rect: TextureRect
var amount_label: Label
var progress_bar: ProgressBar
var status_label: Label
var collect_button: Button

func _ready() -> void:
	add_to_group("production_ui")
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
	panel.custom_minimum_size = Vector2(320, 0)

	var root := VBoxContainer.new()
	panel.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	title_label = Label.new()
	top.add_child(title_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var close := Button.new()
	close.text = "X"
	close.pressed.connect(func(): UIManager.close_menu())
	top.add_child(close)

	var row := HBoxContainer.new()
	root.add_child(row)
	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon_rect)
	amount_label = Label.new()
	row.add_child(amount_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 12)
	progress_bar.max_value = 1.0
	progress_bar.show_percentage = false
	root.add_child(progress_bar)

	status_label = Label.new()
	root.add_child(status_label)

	collect_button = Button.new()
	collect_button.text = "Collecter"
	collect_button.pressed.connect(_on_collect_pressed)
	root.add_child(collect_button)

func open_for_building(building: Node2D) -> void:
	pending_building = building
	UIManager.open_menu("production")

func _process(_delta: float) -> void:
	if visible and current_building != null and is_instance_valid(current_building):
		_refresh()

func _refresh() -> void:
	var b := current_building
	var item: Item = b.produced_item
	icon_rect.texture = item.icon
	amount_label.text = "%s : %d / %d" % [item.display_name, b.stored, b.max_storage]

	progress_bar.value = clampf(b.timer / b.production_time, 0.0, 1.0) if b.production_time > 0.0 else 1.0

	if b.stored >= b.max_storage:
		status_label.text = "Stockage plein : production en pause."
	elif b.stored > 0 and not b.can_collect():
		status_label.text = "Inventaire plein."
	else:
		status_label.text = "En production..."

	collect_button.disabled = not b.can_collect()

func _on_collect_pressed() -> void:
	if current_building != null:
		current_building.collect()
		_refresh()

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "production":
		current_building = pending_building
		title_label.text = "Production : " + current_building.produced_item.display_name
		_refresh()
		UITransitions.show_panel(self)

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "production":
		current_building = null
		UITransitions.hide_panel(self)
