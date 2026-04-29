extends Node2D

const CAVE_W := 480
const CAVE_H := 360
const ENCOUNTER_CHANCE := 0.25

const ROCK_TEX := preload("res://assets/rock.png")
const TALL_GRASS_TEX := preload("res://assets/tall_grass.png")
const POTION_TEX := preload("res://assets/potion.png")
const POKEBALL_TEX := preload("res://assets/pokeball.png")

const ITEM_SPAWNS := [
	{"id": "cave_super_potion_nw", "item": "super_potion", "pos": Vector2(60, 60)},
	{"id": "cave_great_ball_ne",   "item": "great_ball",   "pos": Vector2(420, 60)},
	{"id": "cave_pokeball_sw",     "item": "pokeball",     "pos": Vector2(60, 300)},
]

const TIER_TINTS := {
	"super_potion": Color(0.65, 0.75, 1.30),  # blueish
	"hyper_potion": Color(1.30, 1.15, 0.45),  # yellowish
	"great_ball":   Color(0.65, 0.80, 1.40),  # blueish
	"ultra_ball":   Color(1.40, 1.25, 0.45),  # yellowish
}

const CAVE_REGION := {
	"pool": ["aquillo", "mindling", "pebbleon", "frostling"],
	"night_pool": ["pebbleon", "mindling", "frostling", "frostling"],
	"level_min": 6,
	"level_max": 10,
}

const PATCHES := [
	Vector2(120, 180), Vector2(160, 200), Vector2(200, 180),
	Vector2(280, 220), Vector2(320, 200), Vector2(360, 220),
]

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var hint: Label = $UI/HintLabel
@onready var hud: Label = $UI/HudLabel

var rng := RandomNumberGenerator.new()
var encounter_cooldown := 1.5
var triggered := false
var pause_scene: PackedScene = preload("res://scenes/PauseMenu.tscn")
var night_overlay: ColorRect

func _ready() -> void:
	rng.randomize()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = CAVE_W
	camera.limit_bottom = CAVE_H
	camera.make_current()
	_build_cave()
	_spawn_pickups()
	_create_night_overlay()
	hint.text = "Cave depths.  ESC: pause.  Walk to the south door to exit."
	_refresh_hud()

func _process(delta: float) -> void:
	if encounter_cooldown > 0.0:
		encounter_cooldown -= delta
	if night_overlay:
		night_overlay.color.a = GameState.night_alpha()
	_refresh_hud()

func _create_night_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "NightLayer"
	layer.layer = 0
	add_child(layer)
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

func _build_cave() -> void:
	# perimeter rocks (gap at south for exit)
	var rocks := $Rocks
	for x in range(0, CAVE_W, 32):
		_spawn_rock(rocks, Vector2(x + 16, 16))
		if x >= 208 and x < 272:  # gap for exit door at bottom
			continue
		_spawn_rock(rocks, Vector2(x + 16, CAVE_H - 16))
	for y in range(48, CAVE_H - 32, 32):
		_spawn_rock(rocks, Vector2(16, y + 16))
		_spawn_rock(rocks, Vector2(CAVE_W - 16, y + 16))

	# encounter grass patches
	var patches := $TallGrassPatches
	for p in PATCHES:
		_spawn_grass(patches, p)

	# south exit door
	var door := Area2D.new()
	door.position = Vector2(240, CAVE_H - 18)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 16)
	col.shape = shape
	door.add_child(col)
	add_child(door)
	door.body_entered.connect(_on_exit_door_entered)

func _spawn_rock(parent: Node, pos: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var sprite := Sprite2D.new()
	sprite.texture = ROCK_TEX
	body.add_child(sprite)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(22, 18)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

func _spawn_pickups() -> void:
	var node := Node2D.new()
	node.name = "Pickups"
	add_child(node)
	for entry in ITEM_SPAWNS:
		var pickup_id: String = String(entry["id"])
		if pickup_id in GameState.picked_up_items:
			continue
		var item_id: String = String(entry["item"])
		var area := Area2D.new()
		area.position = entry["pos"]
		var sprite := Sprite2D.new()
		var is_ball: bool = item_id in ItemData.BALL_TIERS
		sprite.texture = POKEBALL_TEX if is_ball else POTION_TEX
		sprite.scale = Vector2(1.5, 1.5)
		if TIER_TINTS.has(item_id):
			sprite.modulate = TIER_TINTS[item_id]
		area.add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(20, 20)
		col.shape = shape
		area.add_child(col)
		area.set_meta("pickup_id", pickup_id)
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
	hint.text = "Picked up a %s!" % ItemData.name_of(item_id)
	area.queue_free()

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
	area.body_entered.connect(_on_grass_entered)

func _on_grass_entered(body: Node2D) -> void:
	if triggered or encounter_cooldown > 0.0:
		return
	if not (body is CharacterBody2D):
		return
	if rng.randf() < ENCOUNTER_CHANCE:
		triggered = true
		encounter_cooldown = 1.0
		var pool: Array = CAVE_REGION["night_pool"] if GameState.is_night() else CAVE_REGION["pool"]
		var lv_min: int = int(CAVE_REGION["level_min"])
		var lv_max: int = int(CAVE_REGION["level_max"])
		var wild_id: String = String(pool[rng.randi() % pool.size()])
		var level: int = rng.randi_range(lv_min, lv_max)
		hint.text = "A wild %s appeared!" % MonsterData.MONSTERS[wild_id]["display_name"]
		await get_tree().create_timer(0.4).timeout
		GameState.start_wild_battle(wild_id, level)
	else:
		encounter_cooldown = 0.5

func _on_exit_door_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	if encounter_cooldown > 0.0:
		return
	encounter_cooldown = 1.0
	# Overworld._ready will see overworld_return_pos and respawn just south of the entrance
	Fade.go_to_scene("res://scenes/Overworld.tscn")
