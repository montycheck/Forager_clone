extends PanelContainer

signal deposited

var item: Item
var needed_amount: int
var station: Node2D

@onready var icon: TextureRect = $Content/Icon
@onready var amount_label: Label = $Content/AmountLabel

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_data(p_item: Item, p_needed: int, p_station: Node2D) -> void:
	item = p_item
	needed_amount = p_needed
	station = p_station
	icon.texture = item.icon
	refresh()

func refresh() -> void:
	var stored = station.get_input_amount(item)
	amount_label.text = "%d / %d" % [stored, needed_amount]

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var available := Inventory.get_item_amount(item)
		var amount := 1

		if event.shift_pressed and event.ctrl_pressed:
			amount = int(available / 2.0)
			if amount <= 0 and available > 0:
				amount = 1
		elif event.shift_pressed:
			amount = available

		if amount > 0:
			station.deposit_item(item, amount)
			refresh()
			deposited.emit()
