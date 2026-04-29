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
var seen_species: Array = []
var playtime_seconds: float = 0.0
var time_of_day: float = 0.0  # 0..1; 0 = noon, 0.5 = midnight, smooth sine

const DAY_LENGTH_SECONDS := 240.0  # 4 minutes per full cycle
const NIGHT_PEAK_ALPHA := 0.45

var overworld_position: Vector2 = Vector2(640, 360)
var overworld_facing: String = "down"
var overworld_return_pos: Vector2 = Vector2.ZERO

# active wild/trainer target during a battle scene
var current_wild: Dictionary = {}
var is_trainer_battle: bool = false
var current_trainer_id: String = ""
var trainer_party_remaining: Array = []

func _ready() -> void:
	if not load_game():
		new_game()

func _process(delta: float) -> void:
	# autoload inherits PROCESS_MODE_PAUSABLE; stops ticking when tree.paused
	playtime_seconds += delta
	time_of_day = fposmod(time_of_day + delta / DAY_LENGTH_SECONDS, 1.0)

func night_alpha() -> float:
	# Smooth sine: 0 at phase 0 / 1, peaks at phase 0.5 (midnight)
	return NIGHT_PEAK_ALPHA * (0.5 - 0.5 * cos(2.0 * PI * time_of_day))

func is_night() -> bool:
	# True during the darker half of the cycle (dusk -> midnight -> dawn).
	return night_alpha() > 0.20

func time_of_day_label() -> String:
	var t: float = time_of_day
	if t < 0.15 or t >= 0.85:
		return "Day"
	if t < 0.35:
		return "Dusk"
	if t < 0.65:
		return "Night"
	return "Dawn"

func mark_seen(species_id: String) -> void:
	if species_id == "":
		return
	if not (species_id in seen_species):
		seen_species.append(species_id)

func new_game(starter_id: String = "pikachu") -> void:
	party = [_make_party_member(starter_id)]
	inventory = {"potion": 3, "pokeball": 5}
	captures = 0
	defeated_trainers = []
	picked_up_items = []
	money = 0
	playtime_seconds = 0.0
	seen_species = []
	mark_seen(starter_id)
	overworld_position = Vector2(640, 360)
	overworld_facing = "down"
	save_game()

func _make_party_member(id: String, level: int = 5) -> Dictionary:
	var m := {
		"id": id,
		"level": level,
		"xp": 0,
		"current_hp": _calc_max_hp(id, level),
		"pp": {},
		"moves": [],
		"status": "",
		"status_turns": 0,
	}
	_sync_moves(m)
	return m

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

func gain_xp(member: Dictionary, amount: int) -> Dictionary:
	var levels_gained: Array = []
	var newly_learned: Array = []
	if amount <= 0:
		return {"levels": levels_gained, "learned": newly_learned}
	member["xp"] = int(member.get("xp", 0)) + amount
	while int(member["xp"]) >= _xp_to_next(int(member.get("level", 5))):
		member["xp"] = int(member["xp"]) - _xp_to_next(int(member["level"]))
		var old_max: int = max_hp_of(member)
		member["level"] = int(member["level"]) + 1
		var new_max: int = max_hp_of(member)
		member["current_hp"] = int(member["current_hp"]) + (new_max - old_max)
		levels_gained.append(int(member["level"]))
		_check_evolution(member)
		for mv in _sync_moves(member):
			newly_learned.append(mv)
	return {"levels": levels_gained, "learned": newly_learned}

func _sync_moves(member: Dictionary) -> Array:
	# Reconcile member['moves'] with the species default + learnset entries up to
	# member['level']. Returns array of move ids newly added to the member.
	var species_id: String = String(member["id"])
	var data: Dictionary = MonsterData.MONSTERS[species_id]
	var lvl: int = int(member.get("level", 5))
	var prev: Array = (member.get("moves", []) as Array).duplicate()
	var moves: Array = (data["moves"] as Array).duplicate()
	var pending: Array = (member.get("pending_learn", []) as Array).duplicate()
	var lset: Dictionary = data.get("learnset", {})
	var sorted_keys: Array = lset.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		var mv: String = String(lset[k])
		if int(k) <= lvl and not (mv in moves) and not (mv in pending):
			if moves.size() < 4:
				moves.append(mv)
			else:
				# 4-cap: defer to player via the move-replace dialog
				pending.append(mv)
	member["moves"] = moves
	member["pending_learn"] = pending
	# Sync pp dict: add full PP for new moves, drop entries for moves no longer present
	var pp = (member.get("pp", {}) as Dictionary).duplicate()
	for mv in moves:
		if not pp.has(mv):
			pp[mv] = int(MoveData.MOVES[mv].get("max_pp", 10))
	for mv in pp.keys():
		if not (mv in moves):
			pp.erase(mv)
	member["pp"] = pp
	# Newly learned = in moves but not in prev
	var newly: Array = []
	for m in moves:
		if not (m in prev):
			newly.append(m)
	return newly

func _check_evolution(member: Dictionary) -> void:
	var data = MonsterData.MONSTERS[member["id"]]
	if not data.has("evolves_at"):
		return
	if int(member["level"]) < int(data["evolves_at"]):
		return
	var new_id: String = String(data["evolves_to"])
	mark_seen(new_id)
	var hp_before: int = int(member["current_hp"])
	var max_before: int = max_hp_of(member)
	member["id"] = new_id
	# clear pp/moves so _sync_moves rebuilds for the new species
	member["pp"] = {}
	member["moves"] = []
	_sync_moves(member)
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
	var result: Dictionary = gain_xp(active, amount)
	var name_after: String = String(MonsterData.MONSTERS[active["id"]]["display_name"])
	summaries.append({
		"name": name_before,
		"xp": amount,
		"levels": result.get("levels", []),
		"learned": result.get("learned", []),
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
			var r2: Dictionary = gain_xp(m, share)
			var n_after: String = String(MonsterData.MONSTERS[m["id"]]["display_name"])
			summaries.append({
				"name": n_before,
				"xp": share,
				"levels": r2.get("levels", []),
				"learned": r2.get("learned", []),
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
	var m := {
		"id": id,
		"level": level,
		"xp": 0,
		"current_hp": current_hp,
		"pp": {},
		"moves": [],
		"status": "",
		"status_turns": 0,
	}
	_sync_moves(m)
	party.append(m)
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

func use_potion_on(member: Dictionary, item_id: String = "potion") -> int:
	if not consume_item(item_id):
		return 0
	var heal: int = int(ItemData.ITEMS.get(item_id, {}).get("heal", 20))
	var max_hp = max_hp_of(member)
	var before = int(member["current_hp"])
	member["current_hp"] = min(max_hp, before + heal)
	return int(member["current_hp"]) - before

func start_trainer_battle(trainer_id: String, party: Array) -> void:
	# party: [{"monster": id, "level": N}, ...]
	if party.is_empty():
		return
	var first: Dictionary = party[0]
	current_wild = _make_wild_dict(String(first["monster"]), int(first["level"]))
	mark_seen(String(first["monster"]))
	trainer_party_remaining = []
	for i in range(1, party.size()):
		trainer_party_remaining.append(party[i])
		mark_seen(String(party[i]["monster"]))
	is_trainer_battle = true
	current_trainer_id = trainer_id
	Fade.go_to_scene("res://scenes/Battle.tscn")

func _make_wild_dict(monster_id: String, level: int) -> Dictionary:
	var max_hp := _calc_max_hp(monster_id, level)
	return {
		"id": monster_id,
		"level": level,
		"max_hp": max_hp,
		"current_hp": max_hp,
		"status": "",
		"status_turns": 0,
	}

func mark_trainer_defeated(trainer_id: String) -> void:
	if trainer_id != "" and not (trainer_id in defeated_trainers):
		defeated_trainers.append(trainer_id)

func start_wild_battle(wild_id: String, level: int = -1) -> void:
	var wild_level: int = level if level > 0 else randi_range(3, 7)
	mark_seen(wild_id)
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
	trainer_party_remaining = []
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
	cfg.set_value("save", "seen_species", seen_species)
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
	seen_species = cfg.get_value("save", "seen_species", [])
	# Make sure starter is always counted (legacy saves predating iter36)
	if seen_species.is_empty():
		mark_seen("pikachu")
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
		if not m.has("pending_learn"):
			m["pending_learn"] = []
		if not m.has("moves"):
			# Legacy save: derive moves + sync pp from current species + level.
			# Discard the returned newly-learned list — no level-up notification.
			_sync_moves(m)
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
