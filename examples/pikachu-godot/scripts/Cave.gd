extends Node2D

const CAVE_W := 480
const CAVE_H := 360
const ENCOUNTER_CHANCE := 0.25

const ROCK_TEX := preload("res://assets/rock.png")
const TALL_GRASS_TEX := preload("res://assets/tall_grass.png")

const CAVE_REGION := {
	"pool": ["aquillo", "mindling", "bunten"],
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

func _ready() -> void:
	rng.randomize()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = CAVE_W
	camera.limit_bottom = CAVE_H
	camera.make_current()
	_build_cave()
	hint.text = "Cave depths.  ESC: pause.  Walk to the south door to exit."
	_refresh_hud()

func _process(delta: float) -> void:
	if encounter_cooldown > 0.0:
		encounter_cooldown -= delta
	_refresh_hud()

func _refresh_hud() -> void:
	var active := GameState.active_monster()
	var disp_name: String = MonsterData.MONSTERS[active["id"]]["display_name"]
	var lv: int = int(active.get("level", 5))
	hud.text = "%s Lv%d  %d/%d HP   $%d   Balls: %d  Potions: %d" % [
		disp_name, lv,
		int(active["current_hp"]),
		GameState.max_hp_of(active),
		GameState.money,
		int(GameState.inventory.get("pokeball", 0)),
		int(GameState.inventory.get("potion", 0)),
	]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
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
		var pool: Array = CAVE_REGION["pool"]
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
