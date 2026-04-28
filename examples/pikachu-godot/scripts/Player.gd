extends CharacterBody2D

@export var speed := 110.0

@onready var sprite: Sprite2D = $Sprite2D

var down_tex := preload("res://assets/pikachu_down.png")
var up_tex := preload("res://assets/pikachu_up.png")
var side_tex := preload("res://assets/pikachu_side.png")

var facing := "down"
var bob_time := 0.0
var dust_timer := 0.0

func _ready() -> void:
	_apply_facing(GameState.overworld_facing)

func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	dir.x = Input.get_axis("ui_left", "ui_right")
	dir.y = Input.get_axis("ui_up", "ui_down")
	if dir.length() > 0.0:
		velocity = dir.normalized() * speed
		bob_time += delta * 10.0
		sprite.position.y = -2 + sin(bob_time) * 1.0
		_update_facing(dir)
		dust_timer += delta
		if dust_timer >= 0.18:
			dust_timer = 0.0
			_spawn_footstep_dust()
	else:
		velocity = Vector2.ZERO
		sprite.position.y = -2
		bob_time = 0.0
		dust_timer = 0.0
	move_and_slide()
	var scene := get_tree().current_scene
	if scene != null and scene.name == "Overworld":
		GameState.overworld_position = position
		GameState.overworld_facing = facing

func _update_facing(dir: Vector2) -> void:
	var new_facing := facing
	if abs(dir.x) > abs(dir.y):
		new_facing = "right" if dir.x > 0 else "left"
	else:
		new_facing = "down" if dir.y > 0 else "up"
	if new_facing != facing:
		_apply_facing(new_facing)

func _spawn_footstep_dust() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var dust := ColorRect.new()
	dust.color = Color(0.85, 0.80, 0.65, 0.55)
	dust.size = Vector2(6, 3)
	dust.position = position + Vector2(-3, 7)
	dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dust)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dust, "modulate:a", 0.0, 0.5)
	tw.tween_property(dust, "size:x", 12.0, 0.5)
	tw.tween_property(dust, "position:x", dust.position.x - 3, 0.5)
	tw.finished.connect(dust.queue_free)

func _apply_facing(new_facing: String) -> void:
	facing = new_facing
	match facing:
		"down":
			sprite.texture = down_tex
			sprite.flip_h = false
		"up":
			sprite.texture = up_tex
			sprite.flip_h = false
		"left":
			sprite.texture = side_tex
			sprite.flip_h = true
		"right":
			sprite.texture = side_tex
			sprite.flip_h = false
