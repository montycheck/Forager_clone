extends HBoxContainer

@onready var icon: TextureRect = $Icon
@onready var amount_label: Label = $AmountLabel

func set_data(item: Item, amount: int):
	icon.texture = item.icon
	amount_label.text = "x%d" % amount
