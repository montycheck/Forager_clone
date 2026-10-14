extends Node

signal network_changed

const EXPORT_INTERVAL := 0.5

var items: Dictionary = {}
var core: Node2D = null
var towers: Array[Node2D] = []
var exporters: Array[Node2D] = []
var _export_timer: float = 0.0
var _rr_pointer: Dictionary = {}   # item_id -> index du prochain exporteur

func is_active():
	return core != null and is_instance_valid(core)
	
func register_core(node: Node2D):
	core = node
	network_changed.emit()

func unregister_core(node: Node2D):
	if core == node:
		core = null
		network_changed.emit()
		
func register_tower(node: Node2D):
	if not towers.has(node):
		towers.append(node)
		network_changed.emit()

func unregister_tower(node: Node2D):
	if towers.has(node):
		towers.erase(node)
		network_changed.emit()

func register_exporter(node: Node2D) -> void:
	if not exporters.has(node):
		exporters.append(node)

func unregister_exporter(node: Node2D) -> void:
	exporters.erase(node)

func _process(delta: float) -> void:
	if exporters.is_empty() or not is_active():
		return
	_export_timer += delta
	if _export_timer < EXPORT_INTERVAL:
		return
	_export_timer = 0.0
	_run_exporters()

func _run_exporters() -> void:
	# item_id -> exporteurs qui veulent cet item
	var by_item: Dictionary = {}
	for exporter in exporters:
		if not is_instance_valid(exporter):
			continue
		for id in exporter.allowed_ids:
			if not items.has(id):
				continue
			if not by_item.has(id):
				by_item[id] = []
			by_item[id].append(exporter)

	var changed := false

	for id in by_item:
		var list: Array = by_item[id]
		var item: Item = items[id]["item"]

		var budget: Dictionary = {}
		for e in list:
			budget[e] = e.amount_per_tick

		var i: int = _rr_pointer.get(id, 0) % list.size()
		var failures := 0

		# Une unité à la fois, en tournant d'un exporteur à l'autre
		while items.has(id) and failures < list.size():
			var e = list[i % list.size()]
			i += 1
			if budget[e] > 0 and e.offer(item, 1) > 0:
				items[id]["amount"] -= 1
				if items[id]["amount"] <= 0:
					items.erase(id)
				budget[e] -= 1
				failures = 0
				changed = true
			else:
				failures += 1

		_rr_pointer[id] = i % list.size()

	if changed:
		network_changed.emit()

func get_capacity() -> int:
	var total := 0
	for t in towers:
		if is_instance_valid(t):
			total += t.capacity
	return total
	
func get_used() -> int:
	var total := 0
	for id in items:
		total += items[id]["amount"]
	return total
	
func get_free_space() -> int:
	return maxi(get_capacity() - get_used(), 0)
	
func add_item(item: Item, amount: int) -> int:
	if not is_active() or amount <= 0:
		return 0
	var to_add = min(amount, get_free_space())
	if to_add <= 0:
		return 0
	if items.has(item.id):
		items[item.id]["amount"] += to_add
	else:
		items[item.id] = {"item": item, "amount": to_add}
	network_changed.emit()
	return to_add

func remove_item(item: Item, amount: int) -> int:
	if not items.has(item.id) or amount <= 0:
		return 0
	var to_remove = mini(amount, items[item.id]["amount"])
	items[item.id]["amount"] -= to_remove
	if items[item.id]["amount"] <= 0:
		items.erase(item.id)
	network_changed.emit()
	return to_remove
	
func get_amount(item: Item) -> int:
	return items[item.id]["amount"] if items.has(item.id) else 0
	
func reset():
	items.clear()
	network_changed.emit()
	
func save_data() -> Array:
	var result: Array = []
	for id in items:
		result.append({
			"item_path": items[id]["item"].resource_path,
			"amount": items[id]["amount"]
		})
	return result

func load_data(data: Array):
	items.clear()
	for entry in data:
		var item: Item = load(entry["item_path"])
		items[item.id] = {"item": item, "amount": entry["amount"]}
	network_changed.emit()
