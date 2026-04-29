extends CanvasLayer

@onready var resume_btn: Button = $Panel/V/ResumeButton
@onready var potion_btn: Button = $Panel/V/PotionButton
@onready var ether_btn: Button = $Panel/V/EtherButton
@onready var held_btn: Button = $Panel/V/HeldButton
@onready var pokedex_btn: Button = $Panel/V/PokedexButton
@onready var save_btn: Button = $Panel/V/SaveButton
@onready var title_btn: Button = $Panel/V/TitleButton

var pokedex_scene: PackedScene = preload("res://scenes/PokedexMenu.tscn")
var choice_scene: PackedScene = preload("res://scenes/ChoiceDialog.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	resume_btn.pressed.connect(_resume)
	potion_btn.pressed.connect(_use_potion)
	ether_btn.pressed.connect(_use_ether)
	held_btn.pressed.connect(_manage_held)
	pokedex_btn.pressed.connect(_open_pokedex)
	save_btn.pressed.connect(_save)
	title_btn.pressed.connect(_to_title)
	$Panel/V/Status.text = _summary_text()

func _summary_text() -> String:
	var t: int = int(GameState.playtime_seconds)
	var h: int = t / 3600
	var m: int = (t % 3600) / 60
	var s: int = t % 60
	var time_str: String = ("%dh %02dm" % [h, m]) if h > 0 else ("%dm %02ds" % [m, s])
	return "%s   |   Party: %d   |   Captured: %d   |   $%d" % [
		time_str, GameState.party.size(), GameState.captures, GameState.money,
	]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_resume()
		get_viewport().set_input_as_handled()

func _resume() -> void:
	get_tree().paused = false
	queue_free()

func _use_ether() -> void:
	var count: int = int(GameState.inventory.get("max_ether", 0))
	if count <= 0:
		$Panel/V/Status.text = "No Max Ether in bag."
		return
	var labels: Array = []
	for m in GameState.party:
		labels.append("%s Lv%d" % [
			MonsterData.MONSTERS[m["id"]]["display_name"],
			int(m.get("level", 5)),
		])
	labels.append("Cancel")
	var dlg = choice_scene.instantiate()
	dlg.set_data("Use Max Ether on whom?  (have %d)" % count, labels)
	get_parent().add_child(dlg)
	var idx: int = await dlg.chosen
	if idx < 0 or idx >= GameState.party.size():
		return
	var refilled: int = GameState.use_ether_on(GameState.party[idx])
	GameState.save_game()
	$Panel/V/Status.text = "Restored %d total PP." % refilled

func _manage_held() -> void:
	# Pick a member
	var labels: Array = []
	for m in GameState.party:
		var holding: String = String(m.get("held_item", ""))
		var hold_str: String = "  (%s)" % ItemData.held_name(holding) if holding != "" else "  (—)"
		labels.append("%s%s" % [
			MonsterData.MONSTERS[m["id"]]["display_name"], hold_str,
		])
	labels.append("Cancel")
	var dlg = choice_scene.instantiate()
	dlg.set_data("Manage held items — pick a member.", labels)
	get_parent().add_child(dlg)
	var idx: int = await dlg.chosen
	if idx < 0 or idx >= GameState.party.size():
		return
	var member: Dictionary = GameState.party[idx]
	var current: String = String(member.get("held_item", ""))
	# Build action list: unequip + each item in inventory that's a held item
	var actions: Array = []  # list of {kind: "unequip"|"equip", item: id}
	if current != "":
		actions.append({"kind": "unequip", "item": current})
	for hid in ItemData.HELD_ITEMS.keys():
		if int(GameState.inventory.get(hid, 0)) > 0:
			actions.append({"kind": "equip", "item": String(hid)})
	if actions.is_empty():
		$Panel/V/Status.text = "No held items in bag and nothing equipped."
		return
	var alabels: Array = []
	for a in actions:
		var name: String = ItemData.held_name(a["item"])
		if a["kind"] == "unequip":
			alabels.append("Unequip %s → bag" % name)
		else:
			alabels.append("Equip %s  x%d" % [name, int(GameState.inventory[a["item"]])])
	alabels.append("Cancel")
	var dlg2 = choice_scene.instantiate()
	var member_name: String = MonsterData.MONSTERS[member["id"]]["display_name"]
	dlg2.set_data("%s — what to do?" % member_name, alabels)
	get_parent().add_child(dlg2)
	var aidx: int = await dlg2.chosen
	if aidx < 0 or aidx >= actions.size():
		return
	var action: Dictionary = actions[aidx]
	if String(action["kind"]) == "unequip":
		member["held_item"] = ""
		GameState.grant_item(String(action["item"]), 1)
		$Panel/V/Status.text = "%s unequipped %s." % [member_name, ItemData.held_name(String(action["item"]))]
	else:
		# If member is currently holding something, swap back to bag
		if current != "":
			GameState.grant_item(current, 1)
		member["held_item"] = String(action["item"])
		GameState.consume_item(String(action["item"]))
		$Panel/V/Status.text = "%s now holds %s." % [member_name, ItemData.held_name(String(action["item"]))]
	GameState.save_game()

func _open_pokedex() -> void:
	var dex := pokedex_scene.instantiate()
	# PokedexMenu also calls get_tree().paused=true; harmless. It will resume on close.
	get_parent().add_child(dex)

func _use_potion() -> void:
	# Pick which tier to use (skip if only 0 or 1)
	var owned: Array = []
	for id in ItemData.POTION_TIERS:
		if int(GameState.inventory.get(id, 0)) > 0:
			owned.append(String(id))
	if owned.is_empty():
		$Panel/V/Status.text = "No potions left."
		return
	var item_id: String
	if owned.size() == 1:
		item_id = owned[0]
	else:
		var labels: Array = []
		for id in owned:
			labels.append("%s  x%d" % [ItemData.name_of(id), int(GameState.inventory[id])])
		labels.append("Cancel")
		var dlg = choice_scene.instantiate()
		dlg.set_data("Use which potion?", labels)
		get_parent().add_child(dlg)
		var idx: int = await dlg.chosen
		if idx < 0 or idx >= owned.size():
			return
		item_id = owned[idx]
	# Pick which party member
	var labels2: Array = []
	for m in GameState.party:
		var max_hp = GameState.max_hp_of(m)
		labels2.append("%s  %d/%d HP" % [
			MonsterData.MONSTERS[m["id"]]["display_name"],
			int(m["current_hp"]), max_hp,
		])
	labels2.append("Cancel")
	var dlg2 = choice_scene.instantiate()
	dlg2.set_data("Use %s on whom?" % ItemData.name_of(item_id), labels2)
	get_parent().add_child(dlg2)
	var idx2: int = await dlg2.chosen
	if idx2 < 0 or idx2 >= GameState.party.size():
		return
	var healed: int = GameState.use_potion_on(GameState.party[idx2], item_id)
	GameState.save_game()
	$Panel/V/Status.text = "Restored %d HP." % healed

func _save() -> void:
	GameState.save_game()
	$Panel/V/Status.text = "Saved.   " + _summary_text()

func _to_title() -> void:
	GameState.save_game()
	get_tree().paused = false
	Fade.go_to_scene("res://scenes/TitleScreen.tscn")
