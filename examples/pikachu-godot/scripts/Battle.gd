extends Node2D

enum State { INTRO, MAIN, MOVE, BAG, PARTY, RESOLVING, ENDING }

const TYPE_COLORS := {
	"normal":   Color(1.00, 1.00, 1.00),
	"electric": Color(1.00, 0.85, 0.30),
	"fire":     Color(1.00, 0.55, 0.30),
	"water":    Color(0.45, 0.70, 1.00),
	"grass":    Color(0.50, 0.95, 0.50),
	"psychic":  Color(1.00, 0.55, 0.85),
}

@onready var enemy_sprite: Sprite2D = $EnemySprite
@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var enemy_name: Label = $UI/EnemyPanel/EnemyName
@onready var enemy_hp_bar: ProgressBar = $UI/EnemyPanel/EnemyHpBar
@onready var enemy_hp_text: Label = $UI/EnemyPanel/EnemyHpText
@onready var player_name: Label = $UI/PlayerPanel/PlayerName
@onready var player_hp_bar: ProgressBar = $UI/PlayerPanel/PlayerHpBar
@onready var player_hp_text: Label = $UI/PlayerPanel/PlayerHpText
@onready var message: Label = $UI/MessagePanel/MessageLabel

@onready var main_menu: Control = $UI/MainMenu
@onready var move_menu: Control = $UI/MoveMenu
@onready var bag_menu: Control = $UI/BagMenu
@onready var party_menu: Control = $UI/PartyMenu

@onready var fight_btn: Button = $UI/MainMenu/Grid/FightButton
@onready var bag_btn: Button = $UI/MainMenu/Grid/BagButton
@onready var party_btn: Button = $UI/MainMenu/Grid/PartyButton
@onready var run_btn: Button = $UI/MainMenu/Grid/RunButton

@onready var move_buttons := [
	$UI/MoveMenu/Grid/Move1, $UI/MoveMenu/Grid/Move2,
	$UI/MoveMenu/Grid/Move3, $UI/MoveMenu/Grid/Move4,
]
@onready var move_back: Button = $UI/MoveMenu/BackButton

@onready var potion_btn: Button = $UI/BagMenu/Grid/PotionButton
@onready var ball_btn: Button = $UI/BagMenu/Grid/BallButton
@onready var bag_back: Button = $UI/BagMenu/BackButton

@onready var party_buttons := [
	$UI/PartyMenu/Grid/Slot1, $UI/PartyMenu/Grid/Slot2,
	$UI/PartyMenu/Grid/Slot3, $UI/PartyMenu/Grid/Slot4,
	$UI/PartyMenu/Grid/Slot5, $UI/PartyMenu/Grid/Slot6,
]
@onready var party_back: Button = $UI/PartyMenu/BackButton

var rng := RandomNumberGenerator.new()
var enemy_status_label: Label
var player_status_label: Label
var party_dots: Array = []
var message_log: Array = []
var player_stages: Dictionary = {"atk": 0, "def": 0}
var enemy_stages: Dictionary = {"atk": 0, "def": 0}
var state: int = State.INTRO
var force_switch := false  # entering party menu because active fainted

func _ready() -> void:
	rng.randomize()
	_create_status_labels()
	_create_party_dots()
	_resize_message_panel()
	fight_btn.pressed.connect(_on_fight_pressed)
	bag_btn.pressed.connect(_on_bag_pressed)
	party_btn.pressed.connect(_on_party_pressed)
	run_btn.pressed.connect(_on_run_pressed)
	move_back.pressed.connect(_show_main_menu)
	bag_back.pressed.connect(_show_main_menu)
	party_back.pressed.connect(_show_main_menu)
	for i in move_buttons.size():
		var idx := i
		(move_buttons[i] as Button).pressed.connect(func(): _on_move_chosen(idx))
	potion_btn.pressed.connect(_use_potion)
	ball_btn.pressed.connect(_throw_ball)
	for i in party_buttons.size():
		var idx := i
		(party_buttons[i] as Button).pressed.connect(func(): _switch_to(idx))

	if GameState.current_wild.is_empty():
		# direct-launch fallback (e.g. running Battle.tscn standalone for testing)
		var fallback_max := GameState._calc_max_hp("volty", 5)
		GameState.current_wild = {
			"id": "volty",
			"level": 5,
			"max_hp": fallback_max,
			"current_hp": fallback_max,
			"status": "",
			"status_turns": 0,
		}
	_setup_visuals()
	$Background.color = GameState.current_battle_bg
	_refresh_bars()
	_set_state(State.INTRO)
	# Intro: slide enemy in from the right and player in from the left
	var enemy_orig := enemy_sprite.position
	var player_orig := player_sprite.position
	enemy_sprite.position = Vector2(enemy_orig.x + 250, enemy_orig.y)
	player_sprite.position = Vector2(player_orig.x - 250, player_orig.y)
	var intro_tw := create_tween()
	intro_tw.set_parallel(true)
	intro_tw.tween_property(enemy_sprite, "position", enemy_orig, 0.45).set_ease(Tween.EASE_OUT)
	intro_tw.tween_property(player_sprite, "position", player_orig, 0.45).set_ease(Tween.EASE_OUT)
	_say("A wild %s appeared!" % MonsterData.MONSTERS[GameState.current_wild["id"]]["display_name"])
	await intro_tw.finished
	await get_tree().create_timer(0.20).timeout
	_say("Go, %s!" % MonsterData.MONSTERS[GameState.active_monster()["id"]]["display_name"])
	await get_tree().create_timer(0.45).timeout
	_show_main_menu()

func _setup_visuals() -> void:
	enemy_sprite.texture = load(MonsterData.MONSTERS[GameState.current_wild["id"]]["sprite"])
	player_sprite.texture = load(MonsterData.MONSTERS[GameState.active_monster()["id"]]["sprite"])
	var wild_lv: int = int(GameState.current_wild.get("level", 5))
	var active_lv: int = int(GameState.active_monster().get("level", 5))
	enemy_name.text = "%s  Lv %d" % [MonsterData.MONSTERS[GameState.current_wild["id"]]["display_name"], wild_lv]
	player_name.text = "%s  Lv %d" % [MonsterData.MONSTERS[GameState.active_monster()["id"]]["display_name"], active_lv]

func _scale_damage(base_dmg: int, attacker_level: int) -> int:
	return max(1, int(round(base_dmg * (1.0 + (attacker_level - 5) * 0.1))))

func _held_atk_mult(member_or_wild: Dictionary) -> float:
	var item: String = String(member_or_wild.get("held_item", ""))
	if item == "" or not ItemData.HELD_ITEMS.has(item):
		return 1.0
	return float(ItemData.HELD_ITEMS[item].get("atk_mult", 1.0))

func _held_def_mult(member_or_wild: Dictionary) -> float:
	var item: String = String(member_or_wild.get("held_item", ""))
	if item == "" or not ItemData.HELD_ITEMS.has(item):
		return 1.0
	return float(ItemData.HELD_ITEMS[item].get("def_mult", 1.0))

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	match state:
		State.MAIN:
			match event.keycode:
				KEY_F: _on_fight_pressed()
				KEY_B: _on_bag_pressed()
				KEY_P: _on_party_pressed()
				KEY_R: _on_run_pressed()
		State.MOVE:
			match event.keycode:
				KEY_1: _on_move_chosen(0)
				KEY_2: _on_move_chosen(1)
				KEY_3: _on_move_chosen(2)
				KEY_4: _on_move_chosen(3)
				KEY_ESCAPE: _show_main_menu()
		State.BAG:
			match event.keycode:
				KEY_1: _use_potion()
				KEY_2: _throw_ball()
				KEY_ESCAPE: _show_main_menu()
		State.PARTY:
			match event.keycode:
				KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
					var idx: int = event.keycode - KEY_1
					_switch_to(idx)
				KEY_ESCAPE:
					if not force_switch:
						_show_main_menu()

func _stage_mult(stages: Dictionary, stat: String) -> float:
	# stage range -3..+3 → 0.7..1.3 (10% per stage)
	return 1.0 + 0.10 * float(stages.get(stat, 0))

func _apply_stat_stage(stages: Dictionary, stat: String, delta: int, label: String) -> void:
	var current: int = int(stages.get(stat, 0))
	var new_val: int = clamp(current + delta, -3, 3)
	if new_val == current:
		var dir := "higher" if delta > 0 else "lower"
		_say("%s's %s won't go %s!" % [label, stat, dir])
		await get_tree().create_timer(0.40).timeout
		return
	stages[stat] = new_val
	if delta > 0:
		_say("%s's %s rose!" % [label, stat])
	else:
		_say("%s's %s fell!" % [label, stat])
	await get_tree().create_timer(0.40).timeout

func _process(_delta: float) -> void:
	Engine.time_scale = 4.0 if Input.is_action_pressed("fast_forward") else 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _can_act(actor: Dictionary, label: String) -> bool:
	var status: String = String(actor.get("status", ""))
	if status == "sleep":
		var turns: int = int(actor.get("status_turns", 0))
		if turns > 0:
			actor["status_turns"] = turns - 1
			_say("%s is fast asleep!" % label)
			await get_tree().create_timer(0.40).timeout
			return false
		actor["status"] = ""
		_refresh_bars()
		_say("%s woke up!" % label)
		await get_tree().create_timer(0.40).timeout
		return true
	if status == "paralyze" and rng.randf() < 0.5:
		_say("%s is paralyzed and can't move!" % label)
		await get_tree().create_timer(0.40).timeout
		return false
	return true

func _apply_burn_damage(actor: Dictionary, label: String, sprite: Sprite2D) -> void:
	if String(actor.get("status", "")) != "burn":
		return
	if int(actor["current_hp"]) <= 0:
		return
	var dmg: int = 2
	actor["current_hp"] = max(0, int(actor["current_hp"]) - dmg)
	await _flash(sprite)
	_spawn_damage_popup(sprite.position, "-%d" % dmg, Color(1.0, 0.6, 0.3))
	_refresh_bars(true)
	_say("%s is hurt by its burn! (-%d HP)" % [label, dmg])
	await get_tree().create_timer(0.40).timeout

func _apply_status_to(target: Dictionary, status_id: String, label: String) -> void:
	if status_id == "" or String(target.get("status", "")) != "":
		_say("But it had no effect.")
		await get_tree().create_timer(0.40).timeout
		return
	target["status"] = status_id
	if status_id == "sleep":
		target["status_turns"] = rng.randi_range(1, 3)
	_refresh_bars()
	match status_id:
		"paralyze": _say("%s is paralyzed!" % label)
		"sleep":    _say("%s fell asleep!" % label)
		"burn":     _say("%s was burned!" % label)
	await get_tree().create_timer(0.40).timeout

func _refresh_bars(animate: bool = false) -> void:
	var wild = GameState.current_wild
	enemy_hp_bar.max_value = wild["max_hp"]
	_set_bar(enemy_hp_bar, int(wild["current_hp"]), animate)
	enemy_hp_text.text = "%d/%d" % [wild["current_hp"], wild["max_hp"]]
	_update_status_label(enemy_status_label, wild)
	var active = GameState.active_monster()
	var max_hp = GameState.max_hp_of(active)
	player_hp_bar.max_value = max_hp
	_set_bar(player_hp_bar, int(active["current_hp"]), animate)
	player_hp_text.text = "%d/%d" % [active["current_hp"], max_hp]
	_update_status_label(player_status_label, active)
	_refresh_party_dots()

func _resize_message_panel() -> void:
	# Make room for 3 stacked log lines (~14px line height at font 11)
	var panel: Panel = $UI/MessagePanel
	panel.offset_top = 178
	panel.offset_bottom = 224
	message.offset_top = 6
	message.offset_bottom = 42
	message.add_theme_font_size_override("font_size", 11)
	message.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

func _say(text: String) -> void:
	message_log.append(text)
	while message_log.size() > 3:
		message_log.pop_front()
	message.text = "\n".join(message_log)

func _create_party_dots() -> void:
	var hbox := HBoxContainer.new()
	hbox.position = Vector2(8, 62)
	hbox.add_theme_constant_override("separation", 2)
	$UI.add_child(hbox)
	for i in 6:
		var lbl := Label.new()
		lbl.text = "●"
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.hide()
		hbox.add_child(lbl)
		party_dots.append(lbl)

func _refresh_party_dots() -> void:
	for i in 6:
		var lbl: Label = party_dots[i]
		if i >= GameState.party.size():
			lbl.hide()
			continue
		lbl.show()
		var m: Dictionary = GameState.party[i]
		var hp: int = int(m.get("current_hp", 0))
		var max_hp: int = GameState.max_hp_of(m)
		var ratio: float = float(hp) / max(1.0, float(max_hp))
		if hp <= 0:
			lbl.modulate = Color(0.45, 0.45, 0.45)
		elif ratio < 0.25:
			lbl.modulate = Color(1.0, 0.40, 0.40)
		elif ratio < 0.5:
			lbl.modulate = Color(1.0, 1.0, 0.40)
		else:
			lbl.modulate = Color(0.45, 1.0, 0.50)

func _create_status_labels() -> void:
	enemy_status_label = _make_status_label()
	enemy_status_label.position = Vector2(212, 4)
	$UI/EnemyPanel.add_child(enemy_status_label)
	player_status_label = _make_status_label()
	player_status_label.position = Vector2(192, 4)
	$UI/PlayerPanel.add_child(player_status_label)

func _make_status_label() -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.hide()
	return lbl

func _update_status_label(lbl: Label, actor: Dictionary) -> void:
	if lbl == null:
		return
	var status: String = String(actor.get("status", ""))
	match status:
		"paralyze":
			lbl.text = "PAR"
			lbl.modulate = Color(1.0, 0.85, 0.30)
			lbl.show()
		"sleep":
			lbl.text = "SLP"
			lbl.modulate = Color(0.55, 0.65, 1.00)
			lbl.show()
		"burn":
			lbl.text = "BRN"
			lbl.modulate = Color(1.0, 0.55, 0.30)
			lbl.show()
		_:
			lbl.hide()

func _spawn_damage_popup(at: Vector2, text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = at + Vector2(-12, -16)
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.z_index = 20
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 26, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.finished.connect(lbl.queue_free)

func _shake_screen(intensity: float = 5.0) -> void:
	var orig: Vector2 = position
	var tw := create_tween()
	for i in 4:
		var off := intensity if i % 2 == 0 else -intensity
		tw.tween_property(self, "position", orig + Vector2(off, 0), 0.04)
	tw.tween_property(self, "position", orig, 0.04)

func _damage_color(eff_mult: float, crit: bool) -> Color:
	if eff_mult > 1.0:
		return Color(1.0, 0.35, 0.35)
	if eff_mult < 1.0:
		return Color(0.75, 0.75, 0.75)
	if crit:
		return Color(1.0, 0.85, 0.4)
	return Color(1.0, 1.0, 0.85)

func _set_bar(bar: ProgressBar, target: int, animate: bool) -> void:
	if animate and int(bar.value) != target:
		var tw := create_tween()
		tw.tween_property(bar, "value", float(target), 0.25)
	else:
		bar.value = target
	# Tint by HP ratio: red <25%, yellow <50%, white otherwise
	var ratio: float = float(target) / max(1.0, float(bar.max_value))
	if ratio < 0.25:
		bar.modulate = Color(1.4, 0.45, 0.45)
	elif ratio < 0.50:
		bar.modulate = Color(1.3, 1.2, 0.45)
	else:
		bar.modulate = Color.WHITE

func _set_state(s: int) -> void:
	state = s
	main_menu.visible = (s == State.MAIN)
	move_menu.visible = (s == State.MOVE)
	bag_menu.visible = (s == State.BAG)
	party_menu.visible = (s == State.PARTY)

func _show_main_menu() -> void:
	if not GameState.has_living_monster():
		_white_out()
		return
	if int(GameState.active_monster()["current_hp"]) <= 0:
		force_switch = true
		_show_party_menu()
		return
	_setup_visuals()
	_refresh_bars()
	_say("What will %s do?" % MonsterData.MONSTERS[GameState.active_monster()["id"]]["display_name"])
	_set_state(State.MAIN)

func _on_fight_pressed() -> void:
	var active = GameState.active_monster()
	var moves = active.get("moves", MonsterData.MONSTERS[active["id"]]["moves"])
	var pp_dict: Dictionary = active.get("pp", {})
	for i in move_buttons.size():
		var btn: Button = move_buttons[i]
		if i < moves.size():
			var move_id: String = moves[i]
			var pp: int = int(pp_dict.get(move_id, 0))
			var max_pp: int = int(MoveData.MOVES[move_id].get("max_pp", 10))
			var move_type: String = String(MoveData.MOVES[move_id].get("type", "normal"))
			btn.text = "%s  %d/%d" % [MoveData.name_of(move_id), pp, max_pp]
			btn.disabled = pp <= 0
			_tint_button_by_type(btn, move_type)
			btn.show()
		else:
			btn.text = "—"
			btn.disabled = true
			_tint_button_by_type(btn, "normal")
			btn.show()
	_set_state(State.MOVE)

func _tint_button_by_type(btn: Button, type_id: String) -> void:
	var c: Color = TYPE_COLORS.get(type_id, Color.WHITE)
	btn.add_theme_color_override("font_color", c)
	btn.add_theme_color_override("font_hover_color", c.lightened(0.15))
	btn.add_theme_color_override("font_pressed_color", c.darkened(0.20))
	btn.add_theme_color_override("font_disabled_color", c.darkened(0.55))

func _on_bag_pressed() -> void:
	var total_potions: int = 0
	for id in ItemData.POTION_TIERS:
		total_potions += int(GameState.inventory.get(id, 0))
	potion_btn.text = "Potions x%d" % total_potions
	potion_btn.disabled = total_potions <= 0
	var total_balls: int = 0
	for id in ItemData.BALL_TIERS:
		total_balls += int(GameState.inventory.get(id, 0))
	if GameState.is_trainer_battle:
		ball_btn.text = "Balls (no use)"
		ball_btn.disabled = true
	else:
		ball_btn.text = "Balls x%d" % total_balls
		ball_btn.disabled = total_balls <= 0
	_set_state(State.BAG)

func _on_party_pressed() -> void:
	force_switch = false
	_show_party_menu()

func _show_party_menu() -> void:
	for i in party_buttons.size():
		var btn: Button = party_buttons[i]
		if i < GameState.party.size():
			var m = GameState.party[i]
			var max_hp = GameState.max_hp_of(m)
			btn.text = "%s  %d/%d" % [MonsterData.MONSTERS[m["id"]]["display_name"], int(m["current_hp"]), max_hp]
			btn.disabled = (i == GameState.active_index() and not force_switch) or int(m["current_hp"]) <= 0
			btn.show()
		else:
			btn.text = "—"
			btn.disabled = true
			btn.show()
	party_back.disabled = force_switch
	_set_state(State.PARTY)

func _on_run_pressed() -> void:
	_set_state(State.RESOLVING)
	if GameState.is_trainer_battle:
		_say("Can't escape from a Trainer battle!")
		await get_tree().create_timer(0.55).timeout
		await _enemy_turn()
		if state != State.ENDING:
			_show_main_menu()
		return
	if rng.randf() < 0.7:
		_say("Got away safely!")
		await get_tree().create_timer(0.55).timeout
		GameState.go_to_overworld()
	else:
		_say("Couldn't escape!")
		await get_tree().create_timer(0.45).timeout
		await _enemy_turn()
		if state != State.ENDING:
			_show_main_menu()

func _on_move_chosen(idx: int) -> void:
	var active = GameState.active_monster()
	var moves = active.get("moves", MonsterData.MONSTERS[active["id"]]["moves"])
	if idx >= moves.size():
		return
	var move_id: String = moves[idx]
	var pp_dict: Dictionary = active.get("pp", {})
	if int(pp_dict.get(move_id, 0)) <= 0:
		return  # safety: button should already be disabled
	var active_label: String = MonsterData.MONSTERS[active["id"]]["display_name"]
	_set_state(State.RESOLVING)
	# Pre-action status check (sleep/paralyze can prevent acting; no PP consumed)
	if await _can_act(active, active_label):
		pp_dict[move_id] = int(pp_dict.get(move_id, 0)) - 1
		active["pp"] = pp_dict
		await _player_uses_move(move_id)
		if state == State.ENDING:
			return
	await _enemy_turn()
	if state == State.ENDING:
		return
	_show_main_menu()

func _player_uses_move(move_id: String) -> void:
	var move = MoveData.MOVES[move_id]
	var move_name := MoveData.name_of(move_id)
	_say("%s used %s!" % [MonsterData.MONSTERS[GameState.active_monster()["id"]]["display_name"], move_name])
	await get_tree().create_timer(0.35).timeout

	if rng.randi_range(1, 100) > int(move["accuracy"]):
		_say("But it missed!")
		await get_tree().create_timer(0.40).timeout
		return

	match String(move["kind"]):
		"damage":
			var raw := rng.randi_range(int(move["min"]), int(move["max"]))
			var attacker_lv: int = int(GameState.active_monster().get("level", 5))
			var dmg := _scale_damage(raw, attacker_lv)
			var move_type: String = String(move.get("type", "normal"))
			var defender_type: String = String(MonsterData.MONSTERS[GameState.current_wild["id"]].get("type", "normal"))
			var eff_mult := MoveData.effectiveness(move_type, defender_type)
			var crit := rng.randi_range(1, 16) == 1
			var crit_mult := 1.5 if crit else 1.0
			var atk_mult := _stage_mult(player_stages, "atk")
			var def_mult := _stage_mult(enemy_stages, "def")
			var weather_mult := GameState.weather_damage_mult(move_type)
			var held_atk := _held_atk_mult(GameState.active_monster())
			var held_def := _held_def_mult(GameState.current_wild)
			dmg = max(1, int(round(dmg * eff_mult * crit_mult * atk_mult / def_mult * weather_mult * held_atk / held_def)))
			GameState.current_wild["current_hp"] = max(0, int(GameState.current_wild["current_hp"]) - dmg)
			await _flash(enemy_sprite)
			_spawn_damage_popup(enemy_sprite.position, "-%d" % dmg, _damage_color(eff_mult, crit))
			_refresh_bars(true)
			if crit:
				_shake_screen()
				_say("Critical hit!")
				await get_tree().create_timer(0.30).timeout
			if eff_mult > 1.0:
				_say("It's super effective! Dealt %d damage." % dmg)
			elif eff_mult < 1.0:
				_say("It's not very effective… Dealt %d damage." % dmg)
			else:
				_say("Dealt %d damage." % dmg)
			await get_tree().create_timer(0.40).timeout
			if int(GameState.current_wild["current_hp"]) <= 0:
				await _victory()
		"heal":
			var amt := rng.randi_range(int(move["min"]), int(move["max"]))
			var active = GameState.active_monster()
			var max_hp = GameState.max_hp_of(active)
			var before = int(active["current_hp"])
			active["current_hp"] = min(max_hp, before + amt)
			_spawn_damage_popup(player_sprite.position, "+%d" % (int(active["current_hp"]) - before), Color(0.4, 1.0, 0.5))
			_refresh_bars(true)
			_say("Recovered %d HP." % (int(active["current_hp"]) - before))
			await get_tree().create_timer(0.40).timeout
		"status":
			var status_id: String = String(move.get("status", ""))
			var wild_label: String = MonsterData.MONSTERS[GameState.current_wild["id"]]["display_name"]
			await _apply_status_to(GameState.current_wild, status_id, wild_label)
		"stat":
			var actor_name: String = MonsterData.MONSTERS[GameState.active_monster()["id"]]["display_name"]
			var foe_name: String = MonsterData.MONSTERS[GameState.current_wild["id"]]["display_name"]
			var target_self: bool = String(move.get("target", "self")) == "self"
			var stages: Dictionary = player_stages if target_self else enemy_stages
			var label: String = actor_name if target_self else foe_name
			await _apply_stat_stage(stages, String(move["stat"]), int(move["delta"]), label)

func _enemy_turn() -> void:
	if int(GameState.current_wild["current_hp"]) <= 0:
		return
	var enemy_label: String = MonsterData.MONSTERS[GameState.current_wild["id"]]["display_name"]
	if await _can_act(GameState.current_wild, enemy_label):
		var moves = MonsterData.MONSTERS[GameState.current_wild["id"]]["moves"]
		var move_id: String = moves[rng.randi() % moves.size()]
		var move = MoveData.MOVES[move_id]
		_say("Wild %s used %s!" % [enemy_label, MoveData.name_of(move_id)])
		await get_tree().create_timer(0.40).timeout
		if rng.randi_range(1, 100) > int(move["accuracy"]):
			_say("But it missed!")
			await get_tree().create_timer(0.35).timeout
		elif String(move["kind"]) == "damage":
			var raw := rng.randi_range(int(move["min"]), int(move["max"]))
			var attacker_lv: int = int(GameState.current_wild.get("level", 5))
			var dmg := _scale_damage(raw, attacker_lv)
			var active = GameState.active_monster()
			var move_type: String = String(move.get("type", "normal"))
			var defender_type: String = String(MonsterData.MONSTERS[active["id"]].get("type", "normal"))
			var eff_mult := MoveData.effectiveness(move_type, defender_type)
			var crit := rng.randi_range(1, 16) == 1
			var crit_mult := 1.5 if crit else 1.0
			var atk_mult := _stage_mult(enemy_stages, "atk")
			var def_mult := _stage_mult(player_stages, "def")
			var weather_mult := GameState.weather_damage_mult(move_type)
			var held_atk := _held_atk_mult(GameState.current_wild)
			var held_def := _held_def_mult(active)
			dmg = max(1, int(round(dmg * eff_mult * crit_mult * atk_mult / def_mult * weather_mult * held_atk / held_def)))
			active["current_hp"] = max(0, int(active["current_hp"]) - dmg)
			await _flash(player_sprite)
			_spawn_damage_popup(player_sprite.position, "-%d" % dmg, _damage_color(eff_mult, crit))
			_refresh_bars(true)
			if crit:
				_shake_screen()
				_say("Critical hit!")
				await get_tree().create_timer(0.30).timeout
			var prefix := ""
			if eff_mult > 1.0:
				prefix = "It's super effective! "
			elif eff_mult < 1.0:
				prefix = "It's not very effective… "
			_say("%s%s took %d damage." % [prefix, MonsterData.MONSTERS[active["id"]]["display_name"], dmg])
			await get_tree().create_timer(0.40).timeout
			if int(active["current_hp"]) <= 0:
				_say("%s fainted!" % MonsterData.MONSTERS[active["id"]]["display_name"])
				await get_tree().create_timer(0.55).timeout
				if not GameState.has_living_monster():
					_white_out()
					return
		elif String(move["kind"]) == "status":
			var status_id: String = String(move.get("status", ""))
			var active = GameState.active_monster()
			var active_label: String = MonsterData.MONSTERS[active["id"]]["display_name"]
			await _apply_status_to(active, status_id, active_label)
		elif String(move["kind"]) == "stat":
			var target_self: bool = String(move.get("target", "self")) == "self"
			var stages: Dictionary = enemy_stages if target_self else player_stages
			var foe_name: String = MonsterData.MONSTERS[GameState.current_wild["id"]]["display_name"]
			var active2 = GameState.active_monster()
			var active_name: String = MonsterData.MONSTERS[active2["id"]]["display_name"]
			var label: String = foe_name if target_self else active_name
			await _apply_stat_stage(stages, String(move["stat"]), int(move["delta"]), label)
	# End-of-round burn ticks (player first, then enemy)
	var active2 = GameState.active_monster()
	if not active2.is_empty() and int(active2["current_hp"]) > 0:
		var active_label2: String = MonsterData.MONSTERS[active2["id"]]["display_name"]
		await _apply_burn_damage(active2, active_label2, player_sprite)
		if int(active2["current_hp"]) <= 0:
			_say("%s fainted!" % active_label2)
			await get_tree().create_timer(0.55).timeout
			if not GameState.has_living_monster():
				_white_out()
				return
	if int(GameState.current_wild["current_hp"]) > 0:
		await _apply_burn_damage(GameState.current_wild, enemy_label, enemy_sprite)
		if int(GameState.current_wild["current_hp"]) <= 0:
			await _victory()

func _flash(node: Sprite2D) -> void:
	var original := node.position
	var tw := create_tween()
	for i in 3:
		tw.tween_property(node, "modulate", Color(1.5, 0.6, 0.6, 1), 0.05)
		tw.tween_property(node, "modulate", Color.WHITE, 0.05)
	for i in 3:
		tw.tween_property(node, "position", original + Vector2(4, 0), 0.04)
		tw.tween_property(node, "position", original - Vector2(4, 0), 0.04)
	tw.tween_property(node, "position", original, 0.04)
	await tw.finished

func _victory() -> void:
	_set_state(State.ENDING)
	var who_word: String = "Trainer's" if GameState.is_trainer_battle else "wild"
	_say("The %s %s fainted! Victory!" % [who_word, MonsterData.MONSTERS[GameState.current_wild["id"]]["display_name"]])
	await get_tree().create_timer(0.60).timeout
	var enemy_lv: int = int(GameState.current_wild.get("level", 5))
	var xp_level: int = enemy_lv * 2 if GameState.is_trainer_battle else enemy_lv
	var is_rematch: bool = false
	if GameState.is_trainer_battle:
		var tid := GameState.current_trainer_id
		if tid in GameState.defeated_trainers:
			# Rematch (already in first-defeat list); track second defeat separately.
			is_rematch = true
			if not (tid in GameState.rematch_completed):
				GameState.rematch_completed.append(tid)
		else:
			GameState.mark_trainer_defeated(tid)
		if tid == "gym_aqua_warden" and not GameState.rematch_unlocked:
			GameState.rematch_unlocked = true
			_say("Rematch challenges unlocked! Defeated trainers will return.")
			await get_tree().create_timer(0.85).timeout
	var summaries: Array = GameState.grant_battle_xp(xp_level)
	for s in summaries:
		_say("%s gained %d XP!" % [s["name"], int(s["xp"])])
		_refresh_bars()
		await get_tree().create_timer(0.45).timeout
		for new_lv in s["levels"]:
			_say("%s grew to Lv %d!" % [s["name"], int(new_lv)])
			_refresh_bars()
			await get_tree().create_timer(0.55).timeout
		var evolved_to: String = String(s.get("evolved_to", ""))
		if evolved_to != "":
			_say("%s evolved into %s!" % [s["name"], evolved_to])
			_setup_visuals()
			_refresh_bars()
			await get_tree().create_timer(0.85).timeout
		for mv_id in s.get("learned", []):
			_say("%s learned %s!" % [s["name"], MoveData.name_of(mv_id)])
			await get_tree().create_timer(0.60).timeout
	# Resolve any pending move-replace prompts (4-move cap)
	for member in GameState.party:
		if int(member.get("current_hp", 0)) <= 0:
			continue
		while not (member.get("pending_learn", []) as Array).is_empty():
			await _resolve_pending_learn(member)
	# Trainer multi-monster: send out the next one and continue battle
	if GameState.is_trainer_battle and not GameState.trainer_party_remaining.is_empty():
		var next: Dictionary = GameState.trainer_party_remaining.pop_front()
		GameState.current_wild = GameState._make_wild_dict(String(next["monster"]), int(next["level"]))
		enemy_stages = {"atk": 0, "def": 0}  # fresh foe gets fresh stages
		_say("Trainer sent out %s!" % MonsterData.MONSTERS[next["monster"]]["display_name"])
		await get_tree().create_timer(0.60).timeout
		_setup_visuals()
		_refresh_bars()
		_show_main_menu()
		return
	var money_reward: int = enemy_lv * (15 if GameState.is_trainer_battle else 5)
	if is_rematch:
		money_reward = int(money_reward * 1.5)
	if money_reward > 0:
		GameState.grant_money(money_reward)
		_say("Got $%d!" % money_reward)
		await get_tree().create_timer(0.55).timeout
	if GameState.is_trainer_battle and GameState.current_trainer_id.begins_with("gym_"):
		GameState.grant_money(100)
		GameState.grant_item("pokeball", 3)
		_say("Gym victory bonus: $100 and 3 Pokeballs!")
		await get_tree().create_timer(0.85).timeout
	GameState.go_to_overworld()

var choice_scene: PackedScene = preload("res://scenes/ChoiceDialog.tscn")

func _resolve_pending_learn(member: Dictionary) -> void:
	var pending: Array = member["pending_learn"]
	if pending.is_empty():
		return
	var new_move: String = String(pending[0])
	var member_name: String = MonsterData.MONSTERS[member["id"]]["display_name"]
	var current_moves: Array = member.get("moves", [])
	var labels: Array = []
	for mv in current_moves:
		labels.append(MoveData.name_of(String(mv)))
	labels.append("Don't learn %s" % MoveData.name_of(new_move))
	var title: String = "%s wants to learn\n%s.\nForget which move?" % [
		member_name, MoveData.name_of(new_move),
	]
	var dlg = choice_scene.instantiate()
	dlg.set_data(title, labels)
	add_child(dlg)
	var idx: int = await dlg.chosen
	if idx >= 0 and idx < current_moves.size():
		var forgotten: String = String(current_moves[idx])
		current_moves[idx] = new_move
		member["moves"] = current_moves
		var pp: Dictionary = (member.get("pp", {}) as Dictionary).duplicate()
		pp.erase(forgotten)
		pp[new_move] = int(MoveData.MOVES[new_move].get("max_pp", 10))
		member["pp"] = pp
		_say("%s forgot %s and learned %s!" % [
			member_name, MoveData.name_of(forgotten), MoveData.name_of(new_move),
		])
		await get_tree().create_timer(0.60).timeout
	else:
		_say("%s did not learn %s." % [member_name, MoveData.name_of(new_move)])
		await get_tree().create_timer(0.45).timeout
	pending.pop_front()
	member["pending_learn"] = pending

func _white_out() -> void:
	_set_state(State.ENDING)
	_say("All your monsters fainted... rushing back!")
	await get_tree().create_timer(0.85).timeout
	GameState.heal_party_full()
	GameState.overworld_position = Vector2(640, 360)
	GameState.go_to_overworld()

func _use_potion() -> void:
	var item_id: String = await _pick_tier(ItemData.POTION_TIERS, "Use which potion?")
	if item_id == "":
		return
	_set_state(State.RESOLVING)
	var active = GameState.active_monster()
	var healed = GameState.use_potion_on(active, item_id)
	_refresh_bars(true)
	_say("Used a %s. Restored %d HP." % [ItemData.name_of(item_id), healed])
	await get_tree().create_timer(0.55).timeout
	await _enemy_turn()
	if state != State.ENDING:
		_show_main_menu()

func _pick_tier(tiers: Array, prompt: String) -> String:
	var owned: Array = []
	for id in tiers:
		if int(GameState.inventory.get(id, 0)) > 0:
			owned.append(String(id))
	if owned.is_empty():
		return ""
	if owned.size() == 1:
		return owned[0]
	var labels: Array = []
	for id in owned:
		labels.append("%s  x%d" % [ItemData.name_of(id), int(GameState.inventory[id])])
	labels.append("Cancel")
	var dlg = choice_scene.instantiate()
	dlg.set_data(prompt, labels)
	add_child(dlg)
	var idx: int = await dlg.chosen
	if idx < 0 or idx >= owned.size():
		return ""
	return owned[idx]

func _throw_ball() -> void:
	var item_id: String = await _pick_tier(ItemData.BALL_TIERS, "Throw which ball?")
	if item_id == "":
		return
	_set_state(State.RESOLVING)
	GameState.consume_item(item_id)
	_say("Threw a %s!" % ItemData.name_of(item_id))
	await get_tree().create_timer(0.40).timeout
	var hp_ratio = float(GameState.current_wild["current_hp"]) / float(GameState.current_wild["max_hp"])
	var bonus: float = float(ItemData.ITEMS[item_id].get("bonus", 0.0))
	var streak_bonus: float = min(GameState.catch_streak, 6) * 0.05
	var chance: float = clamp(0.85 - hp_ratio * 0.7 + bonus + streak_bonus, 0.1, 0.99)
	var caught := rng.randf() < chance
	# wobble animation
	var tw := create_tween()
	for i in 3:
		tw.tween_property(enemy_sprite, "rotation", 0.2, 0.12)
		tw.tween_property(enemy_sprite, "rotation", -0.2, 0.12)
	tw.tween_property(enemy_sprite, "rotation", 0.0, 0.08)
	await tw.finished
	if caught:
		var added = GameState.add_to_party(GameState.current_wild["id"], int(GameState.current_wild["current_hp"]), int(GameState.current_wild.get("level", 5)))
		GameState.catch_streak += 1
		if added:
			_say("Gotcha! %s caught — streak %d!" % [MonsterData.MONSTERS[GameState.current_wild["id"]]["display_name"], GameState.catch_streak])
		else:
			_say("Caught (streak %d)! But the party is full — released." % GameState.catch_streak)
		await get_tree().create_timer(0.85).timeout
		_set_state(State.ENDING)
		GameState.go_to_overworld()
		return
	GameState.catch_streak = 0
	_say("It broke free! (Streak reset)")
	await get_tree().create_timer(0.45).timeout
	await _enemy_turn()
	if state != State.ENDING:
		_show_main_menu()

func _switch_to(idx: int) -> void:
	if idx >= GameState.party.size():
		return
	if int(GameState.party[idx]["current_hp"]) <= 0:
		return
	if idx == GameState.active_index() and not force_switch:
		return
	# move chosen member to front of "alive" order: easiest is to move to slot 0
	var chosen = GameState.party[idx]
	GameState.party.remove_at(idx)
	GameState.party.insert(0, chosen)
	player_stages = {"atk": 0, "def": 0}  # fresh switch-in resets stat stages
	force_switch = false
	_set_state(State.RESOLVING)
	_setup_visuals()
	_refresh_bars()
	_say("Go, %s!" % MonsterData.MONSTERS[chosen["id"]]["display_name"])
	await get_tree().create_timer(0.55).timeout
	await _enemy_turn()
	if state != State.ENDING:
		_show_main_menu()
