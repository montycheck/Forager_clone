extends PanelContainer

signal building_selected(building: Building)

@export var building: Building

const IngredientBadgeScene := preload("res://scenes/ui/ingredient_badge.tscn")

@onready var icon: TextureRect = $Content/Icon
@onready var name_label: Label = $Content/InfoBox/NameLabel
@onready var cost_box: HBoxContainer = $Content/InfoBox/CostBox
@onready var select_button: Button = $Content/SelectButton

var style_insufficient: StyleBoxFlat

func _ready() -> void:
	_build_styles()

	select_button.pressed.connect(_on_select_pressed)
	PlayerProgress.skill_points_changed.connect(_update_state)
	Inventory.inventory_changed.connect(_update_state)

	if building != null:
		icon.texture = building.icon
		name_label.text = building.display_name
		_build_cost_display()

	_update_state()

func _build_styles() -> void:
	style_insufficient = StyleBoxFlat.new()
	style_insufficient.bg_color = Color("#3a2424")
	style_insufficient.set_corner_radius_all(10)
	style_insufficient.set_border_width_all(2)
	style_insufficient.border_color = Color("#c0392b")
	style_insufficient.content_margin_left = 20
	style_insufficient.content_margin_right = 20
	style_insufficient.content_margin_top = 10
	style_insufficient.content_margin_bottom = 10

func _build_cost_display() -> void:
	for i in building.cost_items.size():
		var badge := IngredientBadgeScene.instantiate()
		cost_box.add_child(badge)
		badge.set_data(building.cost_items[i], building.cost_amounts[i])

func _update_state() -> void:
	var skill_ok := building.required_skill_id == "" or PlayerProgress.is_skill_unlocked(building.required_skill_id)

	if not skill_ok:
		select_button.text = "Verrouillé"
		select_button.disabled = true
		select_button.remove_theme_stylebox_override("normal")
		select_button.remove_theme_stylebox_override("disabled")
		return

	var cost_ok := Inventory.has_items(building.cost_items, building.cost_amounts)

	if not cost_ok:
		select_button.text = "Ressources insuffisantes"
		select_button.disabled = true
		select_button.add_theme_stylebox_override("disabled", style_insufficient)
	else:
		select_button.text = "Construire"
		select_button.disabled = false
		select_button.remove_theme_stylebox_override("normal")
		select_button.remove_theme_stylebox_override("disabled")

func _on_select_pressed() -> void:
	building_selected.emit(building)
