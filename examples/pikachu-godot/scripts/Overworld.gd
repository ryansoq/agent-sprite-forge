extends Node2D

const ENCOUNTER_CHANCE := 0.18
const WORLD_W := 1280
const WORLD_H := 720

const TREE_SCENE_TEX := preload("res://assets/tree.png")
const ROCK_TEX := preload("res://assets/rock.png")
const TALL_GRASS_TEX := preload("res://assets/tall_grass.png")
const WATER_TEX := preload("res://assets/water.png")
const TRAINER_TEX := preload("res://assets/trainer.png")
const SHOPKEEPER_TEX := preload("res://assets/shopkeeper.png")
const NPC_ELDER_TEX := preload("res://assets/npc_elder.png")
const GYM_LEADER_TEX := preload("res://assets/gym_leader.png")
const POTION_TEX := preload("res://assets/potion.png")
const POKEBALL_TEX := preload("res://assets/pokeball.png")
const CAVE_ENTRANCE_TEX := preload("res://assets/cave_entrance.png")

const CAVE_DOORS := [
	{"id": "cave_north", "pos": Vector2(220, 80)},
]

const TRAINERS := [
	{"id": "trainer_volty",    "party": [{"monster": "volty", "level": 6}],                                            "pos": Vector2(880, 300)},
	{"id": "trainer_twigling", "party": [{"monster": "twigling", "level": 7}],                                         "pos": Vector2(260, 460)},
	{"id": "trainer_aquillo",  "party": [{"monster": "aquillo", "level": 8}, {"monster": "mindling", "level": 7}],     "pos": Vector2(1020, 540)},
	{"id": "trainer_bunten",   "party": [{"monster": "bunten", "level": 9}],                                           "pos": Vector2(520, 280)},
	{"id": "trainer_mindling", "party": [{"monster": "mindling", "level": 10}, {"monster": "twigling", "level": 8}],   "pos": Vector2(740, 600)},
]

const SHOPS := [
	{"id": "shop_main", "pos": Vector2(560, 360)},
]

const GYM_LEADERS := [
	{
		"id": "gym_thunder_lord",
		"name": "Thunder Lord",
		"party": [{"monster": "embertail", "level": 10}, {"monster": "mindling", "level": 9}],
		"pos": Vector2(1100, 100),
		"pre_dialogue": [
			"So, you've reached me at last.",
			"I am the Thunder Lord, sovereign of this forest.",
			"Few trainers walk away from this fight. Are you ready?",
		],
	},
	{
		"id": "gym_aqua_warden",
		"name": "Aqua Warden",
		"party": [{"monster": "aquillo", "level": 14}, {"monster": "pebbleon", "level": 12}],
		"pos": Vector2(380, 100),
		"pre_dialogue": [
			"Another trainer. So Thunder Lord let you pass…",
			"I am the Aqua Warden of the western springs.",
			"My Aquillo has weathered storms greater than yours. Show me your fight.",
		],
	},
]

const LAYOUT_PATH := "res://data/overworld_layout.json"

const ITEM_SPAWNS := [
	{"id": "pickup_potion_nw",  "item": "potion",       "pos": Vector2(160, 220)},
	{"id": "pickup_ball_ne",    "item": "pokeball",     "pos": Vector2(1100, 200)},
	{"id": "pickup_potion_e",   "item": "potion",       "pos": Vector2(940, 480)},
	{"id": "pickup_ball_sw",    "item": "pokeball",     "pos": Vector2(200, 600)},
	{"id": "pickup_shield_se",  "item": "shield_charm", "pos": Vector2(1140, 600)},
]

const MOVE_TUTORS := [
	{"id": "tutor_main", "name": "Move Tutor", "pos": Vector2(560, 200)},
]

const NPCS := [
	{
		"id": "elder",
		"name": "Elder",
		"texture": "elder",
		"pos": Vector2(720, 360),
		"pages": [
			"Welcome, young trainer!",
			"Catch wild monsters in tall grass with Pokeballs.",
			"Trainers will challenge you on sight — beat them for bigger rewards.",
			"Visit the shop or step on the healing pad whenever you need to recover.",
		],
	},
	{
		"id": "kid",
		"name": "Kid",
		"texture": "elder",
		"pos": Vector2(380, 240),
		"pages": [
			"Whoa, a real Trainer!",
			"I heard there's a powerful one to the north-east…",
			"Train your team well before challenging them!",
		],
	},
]

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var hint: Label = $UI/HintLabel
@onready var hud: Label = $UI/HudLabel
@onready var heal_area: Area2D = $HealingPad/Area2D

var rng := RandomNumberGenerator.new()
var encounter_cooldown := 1.5
var triggered := false
var layout: Dictionary = {}
var night_overlay: ColorRect
var pause_scene: PackedScene = preload("res://scenes/PauseMenu.tscn")
var shop_scene: PackedScene = preload("res://scenes/ShopMenu.tscn")
var dialogue_scene: PackedScene = preload("res://scenes/DialogueBox.tscn")
var choice_scene: PackedScene = preload("res://scenes/ChoiceDialog.tscn")
var nearby_npc: Area2D = null
var nearby_gym_leader: Area2D = null
var nearby_tutor: Area2D = null

func _ready() -> void:
	rng.randomize()
	layout = _load_layout()
	if GameState.overworld_return_pos != Vector2.ZERO:
		# Just exited the cave — spawn south of the entrance to avoid re-trigger
		player.position = GameState.overworld_return_pos + Vector2(0, 36)
		GameState.overworld_position = player.position
		GameState.overworld_return_pos = Vector2.ZERO
	else:
		player.position = GameState.overworld_position
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = WORLD_W
	camera.limit_bottom = WORLD_H
	camera.make_current()
	_build_world()
	_spawn_trainers()
	_spawn_shops()
	_spawn_npcs()
	_spawn_pickups()
	_spawn_gym_leaders()
	_spawn_move_tutors()
	_spawn_cave_doors()
	_create_night_overlay()
	heal_area.body_entered.connect(_on_healing_pad_entered)
	_refresh_hud()
	hint.text = "Arrows: move   ESC: pause   Walk into dark grass for wild encounters!"

func _process(delta: float) -> void:
	if encounter_cooldown > 0.0:
		encounter_cooldown -= delta
	if night_overlay:
		night_overlay.color = GameState.ambient_overlay_color()
	_refresh_hud()

func _create_night_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "NightLayer"
	layer.layer = 0
	add_child(layer)
	# Move just before $UI in tree so UI draws on top
	move_child(layer, $UI.get_index())
	night_overlay = ColorRect.new()
	night_overlay.color = Color(0.05, 0.08, 0.20, 0.0)
	night_overlay.anchor_right = 1.0
	night_overlay.anchor_bottom = 1.0
	night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(night_overlay)

func _refresh_hud() -> void:
	var active := GameState.active_monster()
	var disp_name: String = MonsterData.MONSTERS[active["id"]]["display_name"]
	var lv: int = int(active.get("level", 5))
	var streak_str: String = ("  Streak %d" % GameState.catch_streak) if GameState.catch_streak > 0 else ""
	hud.text = "%s Lv%d  %d/%d HP   $%d   Balls: %d  Potions: %d   [%s · %s]  Seen %d/%d%s" % [
		disp_name, lv,
		int(active["current_hp"]),
		GameState.max_hp_of(active),
		GameState.money,
		int(GameState.inventory.get("pokeball", 0)),
		int(GameState.inventory.get("potion", 0)),
		GameState.time_of_day_label(),
		GameState.current_weather(),
		GameState.seen_species.size(),
		MonsterData.MONSTERS.size(),
		streak_str,
	]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var pause := pause_scene.instantiate()
		add_child(pause)
	elif event.is_action_pressed("interact") and nearby_gym_leader != null:
		var leader := nearby_gym_leader
		var dlg := dialogue_scene.instantiate()
		dlg.set_dialogue_pages(leader.get_meta("pre_dialogue"))
		dlg.closed.connect(_on_gym_dialogue_closed.bind(leader))
		add_child(dlg)
	elif event.is_action_pressed("interact") and nearby_tutor != null:
		_run_tutor_flow()
	elif event.is_action_pressed("interact") and nearby_npc != null:
		var dlg := dialogue_scene.instantiate()
		dlg.set_dialogue_pages(nearby_npc.get_meta("pages"))
		add_child(dlg)

func _build_world() -> void:
	# perimeter trees (every 64px around the edges) — formulaic, stays in code
	var trees := $Trees
	for x in range(0, WORLD_W, 64):
		_spawn(trees, TREE_SCENE_TEX, Vector2(x + 16, 16), true, Vector2(20, 14), Vector2(0, 8))
		_spawn(trees, TREE_SCENE_TEX, Vector2(x + 16, WORLD_H - 16), true, Vector2(20, 14), Vector2(0, 8))
	for y in range(64, WORLD_H - 64, 64):
		_spawn(trees, TREE_SCENE_TEX, Vector2(16, y + 16), true, Vector2(20, 14), Vector2(0, 8))
		_spawn(trees, TREE_SCENE_TEX, Vector2(WORLD_W - 16, y + 16), true, Vector2(20, 14), Vector2(0, 8))

	# scattered inner trees (from layout JSON)
	for arr in layout.get("inner_trees", []):
		_spawn(trees, TREE_SCENE_TEX, _v2(arr), true, Vector2(20, 14), Vector2(0, 8))

	# rocks (from layout JSON)
	var rocks := $Rocks
	for arr in layout.get("rocks", []):
		_spawn(rocks, ROCK_TEX, _v2(arr), true, Vector2(22, 18), Vector2(0, 4))

	# water pond (from layout JSON; rect with optional skip cells)
	var deco := $Decor
	var pond: Dictionary = layout.get("water_pond", {})
	if not pond.is_empty():
		var skip_set := {}
		for sxy in pond.get("skip", []):
			skip_set[_v2(sxy)] = true
		var step: int = int(pond.get("step", 32))
		for x in range(int(pond.get("x_min", 0)), int(pond.get("x_max", 0)), step):
			for y in range(int(pond.get("y_min", 0)), int(pond.get("y_max", 0)), step):
				var tile_pos := Vector2(x, y)
				if skip_set.has(tile_pos):
					continue
				var s := Sprite2D.new()
				s.texture = WATER_TEX
				s.position = tile_pos
				deco.add_child(s)

	# tall grass patches (from layout JSON; tagged by region)
	var patches := $TallGrassPatches
	for entry in layout.get("patches", []):
		_spawn_grass(patches, _v2(entry["pos"]), String(entry["region"]))

func _v2(arr) -> Vector2:
	return Vector2(float(arr[0]), float(arr[1]))

func _load_layout() -> Dictionary:
	var f := FileAccess.open(LAYOUT_PATH, FileAccess.READ)
	if f == null:
		push_warning("Overworld: missing %s; world will be empty." % LAYOUT_PATH)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Overworld: %s is not a JSON object." % LAYOUT_PATH)
		return {}
	return parsed

func _spawn(parent: Node, tex: Texture2D, pos: Vector2, with_collider: bool,
			collider_size: Vector2 = Vector2(20, 14),
			collider_offset: Vector2 = Vector2.ZERO) -> void:
	if with_collider:
		var body := StaticBody2D.new()
		body.position = pos
		var sprite := Sprite2D.new()
		sprite.texture = tex
		body.add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = collider_size
		col.shape = shape
		col.position = collider_offset
		body.add_child(col)
		parent.add_child(body)
	else:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.position = pos
		parent.add_child(sprite)

func _spawn_grass(parent: Node, pos: Vector2, region_id: String = "central_meadow") -> void:
	var area := Area2D.new()
	area.position = pos
	var sprite := Sprite2D.new()
	sprite.texture = TALL_GRASS_TEX
	area.add_child(sprite)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 28)
	col.shape = shape
	area.add_child(col)
	area.set_meta("region_id", region_id)
	parent.add_child(area)
	area.body_entered.connect(_on_tall_grass_entered.bind(area))

func _on_tall_grass_entered(body: Node2D, area: Area2D = null) -> void:
	if triggered or encounter_cooldown > 0.0:
		return
	if not (body is CharacterBody2D):
		return
	if rng.randf() < ENCOUNTER_CHANCE:
		triggered = true
		encounter_cooldown = 1.0
		var region_id: String = "central_meadow"
		if area != null and area.has_meta("region_id"):
			region_id = String(area.get_meta("region_id"))
		var regions: Dictionary = layout.get("regions", {})
		var region: Dictionary = regions.get(region_id, {})
		var pool: Array
		if GameState.is_night() and region.has("night_pool"):
			pool = region["night_pool"]
		else:
			pool = region.get("pool", MonsterData.WILD_POOL)
		var lv_min: int = int(region.get("level_min", 3))
		var lv_max: int = int(region.get("level_max", 7))
		var wild_id: String = String(pool[rng.randi() % pool.size()])
		var level: int = rng.randi_range(lv_min, lv_max)
		hint.text = "A wild %s appeared!" % MonsterData.MONSTERS[wild_id]["display_name"]
		GameState.current_battle_bg = GameState.bg_for_region(region_id)
		await get_tree().create_timer(0.4).timeout
		GameState.start_wild_battle(wild_id, level)
	else:
		encounter_cooldown = 0.5

func _spawn_trainers() -> void:
	var node := Node2D.new()
	node.name = "Trainers"
	add_child(node)
	for t in TRAINERS:
		var party_use = _resolve_party(String(t["id"]), t["party"])
		if party_use == null:
			continue
		var area := Area2D.new()
		area.position = t["pos"]
		var sprite := Sprite2D.new()
		sprite.texture = TRAINER_TEX
		area.add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(22, 28)
		col.shape = shape
		area.add_child(col)
		area.set_meta("trainer_id", String(t["id"]))
		area.set_meta("party", party_use)
		node.add_child(area)
		area.body_entered.connect(_on_trainer_entered.bind(area))
		# Line-of-sight: 22x64 area extending south of the trainer (trainers face down)
		var sight := Area2D.new()
		sight.position = Vector2(t["pos"].x, t["pos"].y + 36)
		var sight_shape := RectangleShape2D.new()
		sight_shape.size = Vector2(22, 64)
		var sight_col := CollisionShape2D.new()
		sight_col.shape = sight_shape
		sight.add_child(sight_col)
		sight.set_meta("trainer_id", String(t["id"]))
		sight.set_meta("party", party_use)
		node.add_child(sight)
		sight.body_entered.connect(_on_trainer_entered.bind(sight))

func _resolve_party(tid: String, base_party: Array):
	# Returns the party Array to spawn with, or null to skip spawning.
	var defeated: bool = tid in GameState.defeated_trainers
	var rematch_done: bool = tid in GameState.rematch_completed
	if not defeated:
		return base_party
	# Aqua Warden is the rematch gate, not itself a rematch target.
	if tid == "gym_aqua_warden":
		return null
	if not GameState.rematch_unlocked or rematch_done:
		return null
	# Build rematch party: same monsters, +5 levels each
	var bumped: Array = []
	for m in base_party:
		bumped.append({"monster": m["monster"], "level": int(m["level"]) + 5})
	return bumped

func _on_trainer_entered(body: Node2D, area: Area2D) -> void:
	if not (body is CharacterBody2D):
		return
	if triggered or encounter_cooldown > 0.0:
		return
	triggered = true
	encounter_cooldown = 1.0
	hint.text = "A Trainer challenges you!"
	await get_tree().create_timer(0.4).timeout
	GameState.start_trainer_battle(
		String(area.get_meta("trainer_id")),
		area.get_meta("party"),
	)

func _spawn_shops() -> void:
	var node := Node2D.new()
	node.name = "Shops"
	add_child(node)
	for s in SHOPS:
		var area := Area2D.new()
		area.position = s["pos"]
		var sprite := Sprite2D.new()
		sprite.texture = SHOPKEEPER_TEX
		area.add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(22, 28)
		col.shape = shape
		area.add_child(col)
		node.add_child(area)
		area.body_entered.connect(_on_shop_entered)

func _on_shop_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	if encounter_cooldown > 0.0:
		return
	encounter_cooldown = 0.6
	var shop := shop_scene.instantiate()
	add_child(shop)

func _spawn_npcs() -> void:
	var node := Node2D.new()
	node.name = "NPCs"
	add_child(node)
	for n in NPCS:
		var area := Area2D.new()
		area.position = n["pos"]
		var sprite := Sprite2D.new()
		sprite.texture = NPC_ELDER_TEX
		area.add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(34, 36)
		col.shape = shape
		area.add_child(col)
		area.set_meta("name", String(n["name"]))
		area.set_meta("pages", n["pages"])
		node.add_child(area)
		area.body_entered.connect(_on_npc_entered.bind(area))
		area.body_exited.connect(_on_npc_exited.bind(area))

func _on_npc_entered(body: Node2D, area: Area2D) -> void:
	if not (body is CharacterBody2D):
		return
	nearby_npc = area
	hint.text = "Press [Space] to talk to %s" % String(area.get_meta("name"))

func _on_npc_exited(body: Node2D, area: Area2D) -> void:
	if not (body is CharacterBody2D):
		return
	if nearby_npc == area:
		nearby_npc = null

func _spawn_pickups() -> void:
	var node := Node2D.new()
	node.name = "Pickups"
	add_child(node)
	for entry in ITEM_SPAWNS:
		if String(entry["id"]) in GameState.picked_up_items:
			continue
		var area := Area2D.new()
		area.position = entry["pos"]
		var sprite := Sprite2D.new()
		var item_id: String = String(entry["item"])
		var is_ball: bool = item_id in ItemData.BALL_TIERS
		sprite.texture = POKEBALL_TEX if is_ball else POTION_TEX
		sprite.scale = Vector2(1.5, 1.5)
		# Tint held items lavender to mark them as special
		if ItemData.HELD_ITEMS.has(item_id):
			sprite.modulate = Color(1.30, 0.80, 1.40)
		area.add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(20, 20)
		col.shape = shape
		area.add_child(col)
		area.set_meta("pickup_id", String(entry["id"]))
		area.set_meta("item_id", item_id)
		node.add_child(area)
		area.body_entered.connect(_on_item_pickup.bind(area))

func _on_item_pickup(body: Node2D, area: Area2D) -> void:
	if not (body is CharacterBody2D):
		return
	var pickup_id: String = String(area.get_meta("pickup_id"))
	if pickup_id in GameState.picked_up_items:
		return
	var item_id: String = String(area.get_meta("item_id"))
	GameState.picked_up_items.append(pickup_id)
	GameState.grant_item(item_id, 1)
	GameState.save_game()
	if ItemData.HELD_ITEMS.has(item_id):
		hint.text = "Picked up %s — equip via Pause menu." % ItemData.held_name(item_id)
	else:
		hint.text = "Picked up a %s!" % ("Potion" if item_id == "potion" else "Pokeball")
	area.queue_free()

func _spawn_gym_leaders() -> void:
	var node := Node2D.new()
	node.name = "GymLeaders"
	add_child(node)
	for g in GYM_LEADERS:
		var party_use = _resolve_party(String(g["id"]), g["party"])
		if party_use == null:
			continue
		var area := Area2D.new()
		area.position = g["pos"]
		var sprite := Sprite2D.new()
		sprite.texture = GYM_LEADER_TEX
		area.add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(34, 36)
		col.shape = shape
		area.add_child(col)
		area.set_meta("id", String(g["id"]))
		area.set_meta("name", String(g["name"]))
		area.set_meta("party", party_use)
		area.set_meta("pre_dialogue", g["pre_dialogue"])
		node.add_child(area)
		area.body_entered.connect(_on_gym_entered.bind(area))
		area.body_exited.connect(_on_gym_exited.bind(area))

func _on_gym_entered(body: Node2D, area: Area2D) -> void:
	if not (body is CharacterBody2D):
		return
	nearby_gym_leader = area
	hint.text = "Press [Space] to challenge %s" % String(area.get_meta("name"))

func _on_gym_exited(body: Node2D, area: Area2D) -> void:
	if not (body is CharacterBody2D):
		return
	if nearby_gym_leader == area:
		nearby_gym_leader = null

func _on_gym_dialogue_closed(leader: Area2D) -> void:
	GameState.start_trainer_battle(
		String(leader.get_meta("id")),
		leader.get_meta("party"),
	)

func _spawn_move_tutors() -> void:
	var node := Node2D.new()
	node.name = "MoveTutors"
	add_child(node)
	for t in MOVE_TUTORS:
		var area := Area2D.new()
		area.position = t["pos"]
		var sprite := Sprite2D.new()
		sprite.texture = NPC_ELDER_TEX
		sprite.modulate = Color(1.1, 1.0, 0.7)  # warmer tint to distinguish
		area.add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(28, 32)
		col.shape = shape
		area.add_child(col)
		area.set_meta("name", String(t["name"]))
		node.add_child(area)
		area.body_entered.connect(_on_tutor_entered.bind(area))
		area.body_exited.connect(_on_tutor_exited.bind(area))

func _on_tutor_entered(body: Node2D, area: Area2D) -> void:
	if not (body is CharacterBody2D):
		return
	nearby_tutor = area
	hint.text = "Press [Space] to talk to %s" % String(area.get_meta("name"))

func _on_tutor_exited(body: Node2D, area: Area2D) -> void:
	if not (body is CharacterBody2D):
		return
	if nearby_tutor == area:
		nearby_tutor = null

func _run_tutor_flow() -> void:
	# 1. Pick a party member
	var labels: Array = []
	for m in GameState.party:
		labels.append("%s Lv%d" % [
			MonsterData.MONSTERS[m["id"]]["display_name"],
			int(m.get("level", 5)),
		])
	labels.append("Cancel")
	var dlg = choice_scene.instantiate()
	dlg.set_data("Teach a forgotten move. Pick a partner.", labels)
	add_child(dlg)
	var idx: int = await dlg.chosen
	if idx < 0 or idx >= GameState.party.size():
		return
	var member: Dictionary = GameState.party[idx]
	# 2. Compute relearnable moves
	var data: Dictionary = MonsterData.MONSTERS[member["id"]]
	var current_moves: Array = member.get("moves", [])
	var lset: Dictionary = data.get("learnset", {})
	var lvl: int = int(member.get("level", 5))
	var candidates: Array = []
	for mv in data["moves"]:
		if not (String(mv) in current_moves):
			candidates.append(String(mv))
	for k in lset.keys():
		if int(k) <= lvl:
			var mv: String = String(lset[k])
			if not (mv in current_moves) and not (mv in candidates):
				candidates.append(mv)
	if candidates.is_empty():
		hint.text = "%s has nothing forgotten to relearn." % MonsterData.MONSTERS[member["id"]]["display_name"]
		return
	# 3. Pick which move to teach
	var move_labels: Array = []
	for mv in candidates:
		move_labels.append(MoveData.name_of(mv))
	move_labels.append("Cancel")
	var dlg2 = choice_scene.instantiate()
	dlg2.set_data("Teach which move?", move_labels)
	add_child(dlg2)
	var midx: int = await dlg2.chosen
	if midx < 0 or midx >= candidates.size():
		return
	var taught: String = candidates[midx]
	# 4. Append directly if room, else replace dialog
	var moves_now: Array = member.get("moves", [])
	if moves_now.size() < 4:
		moves_now.append(taught)
		member["moves"] = moves_now
		var pp: Dictionary = (member.get("pp", {}) as Dictionary).duplicate()
		pp[taught] = int(MoveData.MOVES[taught].get("max_pp", 10))
		member["pp"] = pp
		GameState.save_game()
		hint.text = "%s learned %s!" % [MonsterData.MONSTERS[member["id"]]["display_name"], MoveData.name_of(taught)]
		return
	# 4b. 4-cap: pick which to forget
	var rep_labels: Array = []
	for mv in moves_now:
		rep_labels.append(MoveData.name_of(String(mv)))
	rep_labels.append("Don't learn %s" % MoveData.name_of(taught))
	var dlg3 = choice_scene.instantiate()
	dlg3.set_data("Forget which move to learn %s?" % MoveData.name_of(taught), rep_labels)
	add_child(dlg3)
	var ridx: int = await dlg3.chosen
	if ridx < 0 or ridx >= moves_now.size():
		hint.text = "%s did not learn %s." % [MonsterData.MONSTERS[member["id"]]["display_name"], MoveData.name_of(taught)]
		return
	var forgotten: String = String(moves_now[ridx])
	moves_now[ridx] = taught
	member["moves"] = moves_now
	var pp2: Dictionary = (member.get("pp", {}) as Dictionary).duplicate()
	pp2.erase(forgotten)
	pp2[taught] = int(MoveData.MOVES[taught].get("max_pp", 10))
	member["pp"] = pp2
	GameState.save_game()
	hint.text = "%s forgot %s and learned %s!" % [
		MonsterData.MONSTERS[member["id"]]["display_name"],
		MoveData.name_of(forgotten),
		MoveData.name_of(taught),
	]

func _spawn_cave_doors() -> void:
	var node := Node2D.new()
	node.name = "CaveDoors"
	add_child(node)
	for door_data in CAVE_DOORS:
		var area := Area2D.new()
		area.position = door_data["pos"]
		var sprite := Sprite2D.new()
		sprite.texture = CAVE_ENTRANCE_TEX
		area.add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(28, 22)
		col.shape = shape
		area.add_child(col)
		area.set_meta("entrance_pos", door_data["pos"])
		node.add_child(area)
		area.body_entered.connect(_on_cave_door_entered.bind(area))

func _on_cave_door_entered(body: Node2D, area: Area2D) -> void:
	if not (body is CharacterBody2D):
		return
	if encounter_cooldown > 0.0:
		return
	encounter_cooldown = 1.0
	hint.text = "Entering the cave…"
	GameState.go_to_cave(area.get_meta("entrance_pos"))

func _on_healing_pad_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	GameState.heal_party_full()
	GameState.grant_item("potion", 1)
	hint.text = "Pad: party fully healed and got a Potion!"
	_spawn_heal_sparkles($HealingPad.position)

func _spawn_heal_sparkles(at: Vector2) -> void:
	for i in 8:
		var s := Label.new()
		s.text = "*"
		s.add_theme_font_size_override("font_size", 14)
		s.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
		s.add_theme_constant_override("outline_size", 2)
		s.add_theme_color_override("font_outline_color", Color.BLACK)
		var off := Vector2(rng.randi_range(-14, 14), rng.randi_range(-12, 0))
		s.position = at + off
		s.z_index = 5
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(s)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position:y", s.position.y - 24, 0.7)
		tw.tween_property(s, "modulate:a", 0.0, 0.7)
		tw.finished.connect(s.queue_free)
