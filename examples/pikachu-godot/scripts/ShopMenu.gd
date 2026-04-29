extends CanvasLayer

@onready var money_lbl: Label = $Panel/V/Money
@onready var potion_btn: Button = $Panel/V/PotionButton
@onready var ball_btn: Button = $Panel/V/BallButton
@onready var ether_btn: Button = $Panel/V/EtherButton
@onready var held_btn: Button = $Panel/V/HeldButton
@onready var close_btn: Button = $Panel/V/CloseButton
@onready var status_lbl: Label = $Panel/V/Status

var choice_scene: PackedScene = preload("res://scenes/ChoiceDialog.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	potion_btn.pressed.connect(_buy_potion)
	ball_btn.pressed.connect(_buy_ball)
	ether_btn.pressed.connect(_buy_ether)
	held_btn.pressed.connect(_buy_held)
	close_btn.pressed.connect(_close)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	money_lbl.text = "$%d" % GameState.money
	potion_btn.text = "Buy a potion (3 tiers)"
	potion_btn.disabled = false
	ball_btn.text = "Buy a Pokeball (3 tiers)"
	ball_btn.disabled = false

func _buy_potion() -> void:
	await _buy_from(ItemData.POTION_TIERS, "Buy which potion?")

func _buy_ball() -> void:
	await _buy_from(ItemData.BALL_TIERS, "Buy which ball?")

func _buy_ether() -> void:
	# Direct purchase, no tier picker
	var item_id := "max_ether"
	var price := int(ItemData.ITEMS[item_id]["price"])
	if not GameState.spend_money(price):
		status_lbl.text = "Not enough money for %s." % ItemData.name_of(item_id)
		return
	GameState.grant_item(item_id, 1)
	status_lbl.text = "Bought a %s." % ItemData.name_of(item_id)
	_refresh()

func _buy_held() -> void:
	var ids: Array = ItemData.HELD_ITEMS.keys()
	var labels: Array = []
	for id in ids:
		var entry: Dictionary = ItemData.HELD_ITEMS[id]
		var have: int = int(GameState.inventory.get(id, 0))
		labels.append("%s  $%d  [bag %d]" % [String(entry["name"]), int(entry["price"]), have])
	labels.append("Cancel")
	var dlg = choice_scene.instantiate()
	dlg.set_data("Buy which held item?\n($%d)" % GameState.money, labels)
	add_child(dlg)
	var idx: int = await dlg.chosen
	if idx < 0 or idx >= ids.size():
		return
	var hid: String = String(ids[idx])
	var price: int = int(ItemData.HELD_ITEMS[hid]["price"])
	if not GameState.spend_money(price):
		status_lbl.text = "Not enough money for %s." % ItemData.held_name(hid)
		return
	GameState.grant_item(hid, 1)
	status_lbl.text = "Bought a %s." % ItemData.held_name(hid)
	_refresh()

func _buy_from(tiers: Array, prompt: String) -> void:
	var labels: Array = []
	for id in tiers:
		var entry: Dictionary = ItemData.ITEMS[id]
		var have: int = int(GameState.inventory.get(id, 0))
		labels.append("%s  $%d  [have %d]" % [String(entry["name"]), int(entry["price"]), have])
	labels.append("Cancel")
	var dlg = choice_scene.instantiate()
	dlg.set_data("%s\n($%d)" % [prompt, GameState.money], labels)
	add_child(dlg)
	var idx: int = await dlg.chosen
	if idx < 0 or idx >= tiers.size():
		return
	var item_id: String = String(tiers[idx])
	var price: int = int(ItemData.ITEMS[item_id]["price"])
	if not GameState.spend_money(price):
		status_lbl.text = "Not enough money for %s." % ItemData.name_of(item_id)
		return
	GameState.grant_item(item_id, 1)
	status_lbl.text = "Bought a %s." % ItemData.name_of(item_id)
	_refresh()

func _close() -> void:
	get_tree().paused = false
	GameState.save_game()
	queue_free()
