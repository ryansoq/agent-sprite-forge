extends Node

const SAVE_PATH_TEMPLATE := "user://pikachu_save_%d.cfg"
const TOTAL_SLOTS := 3

var current_slot: int = 1

# party member: { id: String, level: int, xp: int, current_hp: int }
var party: Array = []
var inventory: Dictionary = {}
var captures: int = 0
var defeated_trainers: Array = []
var picked_up_items: Array = []
var money: int = 0
var playtime_seconds: float = 0.0

var overworld_position: Vector2 = Vector2(640, 360)
var overworld_facing: String = "down"
var overworld_return_pos: Vector2 = Vector2.ZERO

# active wild/trainer target during a battle scene
var current_wild: Dictionary = {}
var is_trainer_battle: bool = false
var current_trainer_id: String = ""

func _ready() -> void:
	if not load_game():
		new_game()

func _process(delta: float) -> void:
	# autoload inherits PROCESS_MODE_PAUSABLE; stops ticking when tree.paused
	playtime_seconds += delta

func new_game() -> void:
	party = [_make_party_member("pikachu")]
	inventory = {"potion": 3, "pokeball": 5}
	captures = 0
	defeated_trainers = []
	picked_up_items = []
	money = 0
	playtime_seconds = 0.0
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
		"status": "",
		"status_turns": 0,
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
		_check_evolution(member)
	return levels_gained

func _check_evolution(member: Dictionary) -> void:
	var data = MonsterData.MONSTERS[member["id"]]
	if not data.has("evolves_at"):
		return
	if int(member["level"]) < int(data["evolves_at"]):
		return
	var new_id: String = String(data["evolves_to"])
	var hp_before: int = int(member["current_hp"])
	var max_before: int = max_hp_of(member)
	member["id"] = new_id
	member["pp"] = _init_pp(new_id)
	var max_after: int = max_hp_of(member)
	# bump current HP by the species-change delta so evolution feels rewarding
	member["current_hp"] = min(max_after, hp_before + max(0, max_after - max_before))

func grant_battle_xp(enemy_level: int) -> Array:
	var amount: int = enemy_level * 10
	var summaries: Array = []
	var active := active_monster()
	if active.is_empty():
		return summaries
	var name_before: String = String(MonsterData.MONSTERS[active["id"]]["display_name"])
	var levels := gain_xp(active, amount)
	var name_after: String = String(MonsterData.MONSTERS[active["id"]]["display_name"])
	summaries.append({
		"name": name_before,
		"xp": amount,
		"levels": levels,
		"evolved_to": (name_after if name_after != name_before else ""),
	})
	# Faint XP share: other non-fainted members get half
	var share: int = amount / 2
	if share > 0:
		for m in party:
			if m == active:
				continue
			if int(m.get("current_hp", 0)) <= 0:
				continue
			var n_before: String = String(MonsterData.MONSTERS[m["id"]]["display_name"])
			var lv := gain_xp(m, share)
			var n_after: String = String(MonsterData.MONSTERS[m["id"]]["display_name"])
			summaries.append({
				"name": n_before,
				"xp": share,
				"levels": lv,
				"evolved_to": (n_after if n_after != n_before else ""),
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
		m["status"] = ""
		m["status_turns"] = 0
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
		"status": "",
		"status_turns": 0,
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

func grant_money(amount: int) -> void:
	money = max(0, money + amount)

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	return true

func use_potion_on(member: Dictionary) -> int:
	if not consume_item("potion"):
		return 0
	var max_hp = max_hp_of(member)
	var before = int(member["current_hp"])
	member["current_hp"] = min(max_hp, before + 20)
	return int(member["current_hp"]) - before

func start_trainer_battle(trainer_id: String, monster_id: String, level: int) -> void:
	var max_hp := _calc_max_hp(monster_id, level)
	current_wild = {
		"id": monster_id,
		"level": level,
		"max_hp": max_hp,
		"current_hp": max_hp,
		"status": "",
		"status_turns": 0,
	}
	is_trainer_battle = true
	current_trainer_id = trainer_id
	Fade.go_to_scene("res://scenes/Battle.tscn")

func mark_trainer_defeated(trainer_id: String) -> void:
	if trainer_id != "" and not (trainer_id in defeated_trainers):
		defeated_trainers.append(trainer_id)

func start_wild_battle(wild_id: String, level: int = -1) -> void:
	var wild_level: int = level if level > 0 else randi_range(3, 7)
	var max_hp := _calc_max_hp(wild_id, wild_level)
	current_wild = {
		"id": wild_id,
		"level": wild_level,
		"max_hp": max_hp,
		"current_hp": max_hp,
		"status": "",
		"status_turns": 0,
	}
	Fade.go_to_scene("res://scenes/Battle.tscn")

func go_to_cave(entrance_pos: Vector2) -> void:
	overworld_return_pos = entrance_pos
	save_game()
	Fade.go_to_scene("res://scenes/Cave.tscn")

func go_to_overworld() -> void:
	is_trainer_battle = false
	current_trainer_id = ""
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
	cfg.set_value("save", "defeated_trainers", defeated_trainers)
	cfg.set_value("save", "money", money)
	cfg.set_value("save", "picked_up_items", picked_up_items)
	cfg.set_value("save", "playtime_seconds", playtime_seconds)
	cfg.save(_save_path_for(current_slot))

func _save_path_for(slot: int) -> String:
	return SAVE_PATH_TEMPLATE % slot

func set_slot(slot: int) -> void:
	current_slot = slot

func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(_save_path_for(current_slot)) != OK:
		return false
	party = cfg.get_value("save", "party", [])
	inventory = cfg.get_value("save", "inventory", {})
	overworld_position = cfg.get_value("save", "overworld_position", Vector2(640, 360))
	overworld_facing = cfg.get_value("save", "overworld_facing", "down")
	captures = cfg.get_value("save", "captures", 0)
	defeated_trainers = cfg.get_value("save", "defeated_trainers", [])
	money = cfg.get_value("save", "money", 0)
	picked_up_items = cfg.get_value("save", "picked_up_items", [])
	playtime_seconds = float(cfg.get_value("save", "playtime_seconds", 0.0))
	# backfill level/xp/pp/status on legacy saves
	for m in party:
		if not m.has("level"):
			m["level"] = 5
		if not m.has("xp"):
			m["xp"] = 0
		if not m.has("pp"):
			m["pp"] = _init_pp(String(m["id"]))
		if not m.has("status"):
			m["status"] = ""
		if not m.has("status_turns"):
			m["status_turns"] = 0
	return party.size() > 0

func delete_save(slot: int = -1) -> void:
	var s: int = current_slot if slot < 0 else slot
	var path := _save_path_for(s)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func delete_all_saves() -> void:
	for s in range(1, TOTAL_SLOTS + 1):
		delete_save(s)

func peek_slot(slot: int) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(_save_path_for(slot)) != OK:
		return {}
	return {
		"party_size": (cfg.get_value("save", "party", []) as Array).size(),
		"captures": int(cfg.get_value("save", "captures", 0)),
		"playtime_seconds": float(cfg.get_value("save", "playtime_seconds", 0.0)),
		"money": int(cfg.get_value("save", "money", 0)),
	}
