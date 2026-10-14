extends Control

const COLUMNS := 4

var capacity_label: Label
var capacity_bar: ProgressBar
var search_box: LineEdit
var network_grid: GridContainer
var inventory_grid: GridContainer
var deposit_button: Button
var close_button: Button

func _ready() -> void:
	add_to_group("storage_terminal_ui")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()

	UIManager.menu_opened.connect(_on_menu_opened)
	UIManager.menu_closed.connect(_on_menu_closed)
	StorageNetwork.network_changed.connect(_on_network_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)

func _make_scroll_grid(parent: Control) -> GridContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 240)
	parent.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	return grid

func _build_ui() -> void:
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(900, 440)

	var root := VBoxContainer.new()
	panel.add_child(root)

	# Barre du haut
	var top := HBoxContainer.new()
	root.add_child(top)
	var title := Label.new()
	title.text = "Stockage"
	top.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	close_button = Button.new()
	close_button.text = "X"
	close_button.pressed.connect(func(): UIManager.close_menu())
	top.add_child(close_button)

	# Deux colonnes
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	# Colonne gauche : réseau
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)

	capacity_label = Label.new()
	left.add_child(capacity_label)
	capacity_bar = ProgressBar.new()
	capacity_bar.custom_minimum_size = Vector2(0, 12)
	capacity_bar.show_percentage = false
	left.add_child(capacity_bar)
	search_box = LineEdit.new()
	search_box.placeholder_text = "Rechercher..."
	search_box.text_changed.connect(func(_t): _refresh_network())
	left.add_child(search_box)
	network_grid = _make_scroll_grid(left)

	# Colonne droite : inventaire
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)

	var inv_title := Label.new()
	inv_title.text = "Inventaire (clic : déposer)"
	right.add_child(inv_title)
	inventory_grid = _make_scroll_grid(right)
	deposit_button = Button.new()
	deposit_button.text = "Tout déposer"
	deposit_button.pressed.connect(_on_deposit_all_pressed)
	right.add_child(deposit_button)

func open() -> void:
	UIManager.open_menu("storage_terminal")

# --- Affichage ---
func _refresh() -> void:
	_refresh_network()
	_refresh_inventory()

func _clear(grid: GridContainer) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

func _make_entry(item: Item, amount: int, hint: String) -> Button:
	var b := Button.new()
	b.icon = item.icon
	b.text = str(amount)
	b.custom_minimum_size = Vector2(84, 44)
	b.tooltip_text = "%s\n%s" % [item.display_name, hint]
	return b

func _refresh_network() -> void:
	var capacity := StorageNetwork.get_capacity()
	var used := StorageNetwork.get_used()
	capacity_label.text = "%d / %d" % [used, capacity]
	capacity_bar.max_value = maxf(capacity, 1.0)
	capacity_bar.value = used

	_clear(network_grid)

	var filter := search_box.text.strip_edges().to_lower()
	var entries: Array = StorageNetwork.items.values()
	entries.sort_custom(func(a, b): return a["item"].display_name < b["item"].display_name)

	for entry in entries:
		var item: Item = entry["item"]
		if filter != "" and not item.display_name.to_lower().contains(filter):
			continue
		var b := _make_entry(item, entry["amount"], "Clic : x1 | Maj+clic : tout | Ctrl+Maj+clic : moitié")
		b.gui_input.connect(_on_network_entry_input.bind(item))
		network_grid.add_child(b)

func _get_inventory_totals() -> Dictionary:
	var totals: Dictionary = {}
	for slot in Inventory.slots:
		var id: String = slot["item"].id
		if totals.has(id):
			totals[id]["amount"] += slot["amount"]
		else:
			totals[id] = {"item": slot["item"], "amount": slot["amount"]}
	return totals

func _refresh_inventory() -> void:
	_clear(inventory_grid)
	for entry in _get_inventory_totals().values():
		var item: Item = entry["item"]
		var b := _make_entry(item, entry["amount"], "Clic : déposer x1 | Maj+clic : tout | Ctrl+Maj+clic : moitié")
		b.gui_input.connect(_on_inventory_entry_input.bind(item))
		inventory_grid.add_child(b)

# --- Lecture des clics (partagée) ---
func _read_amount(event: InputEvent, available: int) -> int:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return 0
	if event.shift_pressed and event.ctrl_pressed:
		return maxi(1, int(available / 2.0))
	if event.shift_pressed:
		return available
	return 1

# --- Retrait (réseau -> inventaire) ---
func _on_network_entry_input(event: InputEvent, item: Item) -> void:
	var amount := _read_amount(event, StorageNetwork.get_amount(item))
	if amount > 0:
		_withdraw(item, amount)

func _can_receive(item: Item) -> bool:
	for slot in Inventory.slots:
		if slot["item"].id == item.id and slot["amount"] < item.max_stack:
			return true
	return Inventory.slots.size() < Inventory.max_slots

func _withdraw(item: Item, amount: int) -> void:
	if amount <= 0 or not _can_receive(item):
		return
	var taken := StorageNetwork.remove_item(item, amount)
	if taken > 0:
		Inventory.add_item(item, taken)

# --- Dépôt (inventaire -> réseau) ---
func _on_inventory_entry_input(event: InputEvent, item: Item) -> void:
	var amount := _read_amount(event, Inventory.get_item_amount(item))
	if amount > 0:
		_deposit(item, amount)

func _deposit(item: Item, amount: int) -> void:
	var added := StorageNetwork.add_item(item, amount)
	if added > 0:
		Inventory.remove_item(item, added)

func _on_deposit_all_pressed() -> void:
	for entry in _get_inventory_totals().values():
		_deposit(entry["item"], entry["amount"])

# --- Callbacks ---
func _on_network_changed() -> void:
	if visible:
		_refresh_network()

func _on_inventory_changed() -> void:
	if visible:
		_refresh_inventory()

func _on_menu_opened(menu_name: String) -> void:
	if menu_name == "storage_terminal":
		search_box.text = ""
		_refresh()
		UITransitions.show_panel(self)

func _on_menu_closed(menu_name: String) -> void:
	if menu_name == "storage_terminal":
		UITransitions.hide_panel(self)
