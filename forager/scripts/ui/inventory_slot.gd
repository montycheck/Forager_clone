extends PanelContainer

@onready var icon: TextureRect = $Icon
@onready var amount_badge: PanelContainer = $AmountBadge
@onready var amount_label: Label = $AmountBadge/AmountLabel

func set_slot_data(item: Item, amount: int) -> void:
	icon.texture = item.icon
	if amount > 1:
		amount_label.text = str(amount)
		amount_badge.visible = true
	else:
		amount_badge.visible = false

func set_empty() -> void:
	icon.texture = null
	amount_badge.visible = false
