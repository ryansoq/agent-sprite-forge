extends Node

const SAVE_PATH := "user://pikachu_save.cfg"

# party member: { id: String, level: int, xp: int, current_hp: int }
var party: Array = []
var inventory: Dictionary = {}
var captures: int = 0

var overworld_position: Vector2 = Vector2(640, 360)
var overworld_facing: String = "down"

# active wild target during a battle scene
var current_wild: Dictionary = {}

func _ready() -> void:
	if not load_game():
		new_game()

func new_game() -> void:
	party = [_make_party_member("pikachu")]
	inventory = {"potion": 3, "pokeball": 5}
	captures = 0
	overworld_position = Vector2(640, 360)
	overworld_facing = "down"
	save_game()

func _make_party_member(id: String, level: int = 5) -> Dictionary:
	return {
		"id": id,
		"level": level,
		"xp": 0,
		"current_hp": _calc_max_hp(id, level),
		"pp": _init_pp(id),
	}

func _init_pp(id: String) -> Dictionary:
	var pp := {}
	for move_id in MonsterData.MONSTERS[id]["moves"]:
		pp[move_id] = int(MoveData.MOVES[move_id].get("max_pp", 10))
	return pp

func _calc_max_hp(id: String, level: int) -> int:
	var base: int = int(MonsterData.MONSTERS[id]["max_hp"])
	return base + (level - 5) * max(1, base / 10)

func _xp_to_next(level: int) -> int:
	return level * 25

func gain_xp(member: Dictionary, amount: int) -> Array:
	var levels_gained: Array = []
	if amount <= 0:
		return levels_gained
	member["xp"] = int(member.get("xp", 0)) + amount
	while int(member["xp"]) >= _xp_to_next(int(member.get("level", 5))):
		member["xp"] = int(member["xp"]) - _xp_to_next(int(member["level"]))
		var old_max: int = max_hp_of(member)
		member["level"] = int(member["level"]) + 1
		var new_max: int = max_hp_of(member)
		member["current_hp"] = int(member["current_hp"]) + (new_max - old_max)
		levels_gained.append(int(member["level"]))
	return levels_gained

func grant_battle_xp(enemy_level: int) -> Array:
	var amount: int = enemy_level * 10
	var summaries: Array = []
	var active := active_monster()
	if active.is_empty():
		return summaries
	var levels := gain_xp(active, amount)
	summaries.append({
		"name": String(MonsterData.MONSTERS[active["id"]]["display_name"]),
		"xp": amount,
		"levels": levels,
	})
	return summaries

func active_index() -> int:
	for i in party.size():
		if int(party[i]["current_hp"]) > 0:
			return i
	return 0

func active_monster() -> Dictionary:
	if party.is_empty():
		return {}
	return party[active_index()]

func max_hp_of(member: Dictionary) -> int:
	return _calc_max_hp(String(member["id"]), int(member.get("level", 5)))

func has_living_monster() -> bool:
	for m in party:
		if int(m["current_hp"]) > 0:
			return true
	return false

func heal_party_full() -> void:
	for m in party:
		m["current_hp"] = max_hp_of(m)
		m["pp"] = _init_pp(String(m["id"]))
	save_game()

func add_to_party(id: String, current_hp: int, level: int = 5) -> bool:
	if party.size() >= 6:
		return false
	party.append({
		"id": id,
		"level": level,
		"xp": 0,
		"current_hp": current_hp,
		"pp": _init_pp(id),
	})
	captures += 1
	save_game()
	return true

func consume_item(item: String) -> bool:
	if int(inventory.get(item, 0)) <= 0:
		return false
	inventory[item] = int(inventory[item]) - 1
	if int(inventory[item]) <= 0:
		inventory.erase(item)
	return true

func grant_item(item: String, amount: int) -> void:
	inventory[item] = int(inventory.get(item, 0)) + amount

func use_potion_on(member: Dictionary) -> int:
	if not consume_item("potion"):
		return 0
	var max_hp = max_hp_of(member)
	var before = int(member["current_hp"])
	member["current_hp"] = min(max_hp, before + 20)
	return int(member["current_hp"]) - before

func start_wild_battle(wild_id: String) -> void:
	var wild_level := randi_range(3, 7)
	var max_hp := _calc_max_hp(wild_id, wild_level)
	current_wild = {
		"id": wild_id,
		"level": wild_level,
		"max_hp": max_hp,
		"current_hp": max_hp,
		"paralyzed": false,
	}
	Fade.go_to_scene("res://scenes/Battle.tscn")

func go_to_overworld() -> void:
	save_game()
	Fade.go_to_scene("res://scenes/Overworld.tscn")

func go_to_title() -> void:
	save_game()
	Fade.go_to_scene("res://scenes/TitleScreen.tscn")

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "party", party)
	cfg.set_value("save", "inventory", inventory)
	cfg.set_value("save", "overworld_position", overworld_position)
	cfg.set_value("save", "overworld_facing", overworld_facing)
	cfg.set_value("save", "captures", captures)
	cfg.save(SAVE_PATH)

func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	party = cfg.get_value("save", "party", [])
	inventory = cfg.get_value("save", "inventory", {})
	overworld_position = cfg.get_value("save", "overworld_position", Vector2(640, 360))
	overworld_facing = cfg.get_value("save", "overworld_facing", "down")
	captures = cfg.get_value("save", "captures", 0)
	# backfill level/xp/pp on legacy saves
	for m in party:
		if not m.has("level"):
			m["level"] = 5
		if not m.has("xp"):
			m["xp"] = 0
		if not m.has("pp"):
			m["pp"] = _init_pp(String(m["id"]))
	return party.size() > 0

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
