extends PanelContainer

@onready var icon: TextureRect = $Icon
@onready var amount_badge: PanelContainer = $AmountBadge
@onready var amount_label: Label = $AmountBadge/AmountLabel

var slot_index: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gui_input.connect(_on_gui_input)

func set_slot_data(item: Item, amount: int) -> void:
	icon.texture = item.icon
	if item is ConsumableItem:
		tooltip_text = item.get_description() + "\n(clic droit : utiliser)"
	else:
		tooltip_text = item.display_name
	if amount > 1:
		amount_label.text = str(amount)
		amount_badge.visible = true
	else:
		amount_badge.visible = false

func set_empty() -> void:
	icon.texture = null
	tooltip_text = ""
	amount_badge.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		Inventory.use_slot(slot_index)
