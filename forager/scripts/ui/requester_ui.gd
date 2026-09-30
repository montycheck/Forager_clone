extends Control

const IngredientRowScene := preload("res://scenes/ui/ingredient_deposit_row.tscn")

@onready var title_label: Label = $Panel/Root/TopBar/TitleLabel
@onready var close_button: Button = $Panel/Root/TopBar/CloseButton
@onready var stage_label: Label = $Panel/Root/StageLabel
@onready var deposit_slot: VBoxContainer = $Panel/Root/DepositSlot

var pending_requester: Node2D = null
var current_requester: Node2D = null

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	visible = false

func _process(_delta: float) -> void:
	if visible and current_requester != null:
		_refresh_content()

func open_for_requester(requester: Node2D) -> void:
	pending_requester = requester
	UIManager.open_menu("requester")

func _refresh_content() -> void:
	var stage: ProgressionStage = current_requester.current_stage

	for child in deposit_slot.get_children():
		child.queue_free()

	if stage == null:
		stage_label.text = "Toutes les étapes de ce biome sont terminées."
		return

	stage_label.text = "Étape %d" % stage.stage_number

	var row := IngredientRowScene.instantiate()
	deposit_slot.add_child(row)
	row.set_data(stage.key_item, stage.key_item_amount, current_requester)
	row.deposited.connect(_refresh_content)

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "requester":
		current_requester = pending_requester
		title_label.text = "Requête"
		_refresh_content()
		UITransitions.show_panel(self)

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "requester":
		current_requester = null
		UITransitions.hide_panel(self)

func _on_close_pressed() -> void:
	UIManager.close_menu()
