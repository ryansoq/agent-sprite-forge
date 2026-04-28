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
const POTION_TEX := preload("res://assets/potion.png")
const POKEBALL_TEX := preload("res://assets/pokeball.png")

const TRAINERS := [
	{"id": "trainer_volty", "monster": "volty", "level": 6, "pos": Vector2(880, 300)},
	{"id": "trainer_twigling", "monster": "twigling", "level": 7, "pos": Vector2(260, 460)},
]

const SHOPS := [
	{"id": "shop_main", "pos": Vector2(560, 360)},
]

const ITEM_SPAWNS := [
	{"id": "pickup_potion_nw", "item": "potion",   "pos": Vector2(160, 220)},
	{"id": "pickup_ball_ne",   "item": "pokeball", "pos": Vector2(1100, 200)},
	{"id": "pickup_potion_e",  "item": "potion",   "pos": Vector2(940, 480)},
	{"id": "pickup_ball_sw",   "item": "pokeball", "pos": Vector2(200, 600)},
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
var pause_scene: PackedScene = preload("res://scenes/PauseMenu.tscn")
var shop_scene: PackedScene = preload("res://scenes/ShopMenu.tscn")
var dialogue_scene: PackedScene = preload("res://scenes/DialogueBox.tscn")
var nearby_npc: Area2D = null

func _ready() -> void:
	rng.randomize()
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
	heal_area.body_entered.connect(_on_healing_pad_entered)
	_refresh_hud()
	hint.text = "Arrows: move   ESC: pause   Walk into dark grass for wild encounters!"

func _process(delta: float) -> void:
	if encounter_cooldown > 0.0:
		encounter_cooldown -= delta
	_refresh_hud()

func _refresh_hud() -> void:
	var active := GameState.active_monster()
	var disp_name: String = MonsterData.MONSTERS[active["id"]]["display_name"]
	var lv: int = int(active.get("level", 5))
	hud.text = "%s Lv%d  %d/%d HP   $%d   Balls: %d  Potions: %d   Caught: %d" % [
		disp_name, lv,
		int(active["current_hp"]),
		GameState.max_hp_of(active),
		GameState.money,
		int(GameState.inventory.get("pokeball", 0)),
		int(GameState.inventory.get("potion", 0)),
		GameState.captures,
	]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var pause := pause_scene.instantiate()
		add_child(pause)
	elif event.is_action_pressed("ui_accept") and nearby_npc != null:
		var dlg := dialogue_scene.instantiate()
		dlg.set_dialogue_pages(nearby_npc.get_meta("pages"))
		add_child(dlg)

func _build_world() -> void:
	# perimeter trees (every 64px around the edges)
	var trees := $Trees
	for x in range(0, WORLD_W, 64):
		_spawn(trees, TREE_SCENE_TEX, Vector2(x + 16, 16), true, Vector2(20, 14), Vector2(0, 8))
		_spawn(trees, TREE_SCENE_TEX, Vector2(x + 16, WORLD_H - 16), true, Vector2(20, 14), Vector2(0, 8))
	for y in range(64, WORLD_H - 64, 64):
		_spawn(trees, TREE_SCENE_TEX, Vector2(16, y + 16), true, Vector2(20, 14), Vector2(0, 8))
		_spawn(trees, TREE_SCENE_TEX, Vector2(WORLD_W - 16, y + 16), true, Vector2(20, 14), Vector2(0, 8))

	# scattered inner trees (forest pockets)
	var inner_trees := [
		Vector2(180, 140), Vector2(220, 200), Vector2(160, 260), Vector2(260, 140),
		Vector2(1080, 180), Vector2(1120, 240), Vector2(1060, 260),
		Vector2(900, 540), Vector2(960, 600), Vector2(880, 600),
		Vector2(420, 580), Vector2(360, 540), Vector2(300, 600),
	]
	for p in inner_trees:
		_spawn(trees, TREE_SCENE_TEX, p, true, Vector2(20, 14), Vector2(0, 8))

	# rocks along the west path
	var rocks := $Rocks
	for p in [Vector2(420, 180), Vector2(500, 220), Vector2(580, 180), Vector2(680, 240),
			  Vector2(820, 200), Vector2(140, 480), Vector2(220, 520)]:
		_spawn(rocks, ROCK_TEX, p, true, Vector2(22, 18), Vector2(0, 4))

	# water pond (east) — purely decorative, walkable around
	var deco := $Decor
	for x in range(960, 1216, 32):
		for y in range(440, 600, 32):
			if x in [992, 1024, 1184] and y in [600]:
				continue
			var s := Sprite2D.new()
			s.texture = WATER_TEX
			s.position = Vector2(x, y)
			deco.add_child(s)

	# tall grass patches scattered (encounter zones)
	var patches := $TallGrassPatches
	var patch_positions := [
		Vector2(420, 360), Vector2(460, 380), Vector2(500, 360),
		Vector2(540, 400), Vector2(580, 360), Vector2(620, 400),
		Vector2(720, 440), Vector2(760, 420), Vector2(800, 460),
		Vector2(380, 600), Vector2(420, 620), Vector2(460, 600),
		Vector2(140, 360), Vector2(180, 380), Vector2(220, 360),
		Vector2(1100, 500), Vector2(1140, 480), Vector2(1100, 460),
	]
	for p in patch_positions:
		_spawn_grass(patches, p)

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

func _spawn_grass(parent: Node, pos: Vector2) -> void:
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
	parent.add_child(area)
	area.body_entered.connect(_on_tall_grass_entered)

func _on_tall_grass_entered(body: Node2D) -> void:
	if triggered or encounter_cooldown > 0.0:
		return
	if not (body is CharacterBody2D):
		return
	if rng.randf() < ENCOUNTER_CHANCE:
		triggered = true
		encounter_cooldown = 1.0
		hint.text = "A wild monster appeared!"
		var wild_id: String = MonsterData.WILD_POOL[rng.randi() % MonsterData.WILD_POOL.size()]
		await get_tree().create_timer(0.4).timeout
		GameState.start_wild_battle(wild_id)
	else:
		encounter_cooldown = 0.5

func _spawn_trainers() -> void:
	var node := Node2D.new()
	node.name = "Trainers"
	add_child(node)
	for t in TRAINERS:
		if String(t["id"]) in GameState.defeated_trainers:
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
		area.set_meta("monster_id", String(t["monster"]))
		area.set_meta("level", int(t["level"]))
		node.add_child(area)
		area.body_entered.connect(_on_trainer_entered.bind(area))

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
		String(area.get_meta("monster_id")),
		int(area.get_meta("level")),
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
		sprite.texture = POTION_TEX if item_id == "potion" else POKEBALL_TEX
		sprite.scale = Vector2(1.5, 1.5)
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
	hint.text = "Picked up a %s!" % ("Potion" if item_id == "potion" else "Pokeball")
	area.queue_free()

func _on_healing_pad_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	GameState.heal_party_full()
	GameState.grant_item("potion", 1)
	hint.text = "Pad: party fully healed and got a Potion!"
