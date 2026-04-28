extends Control

@onready var info: Label = $Center/Info
@onready var subtitle: Label = $Center/Subtitle

var slot_buttons: Array = []

func _ready() -> void:
	info.text = "Pick a save slot to continue or start fresh."
	subtitle.text = "[1-3] / click a slot   [R] Reset all saves"
	_build_slot_buttons()

func _build_slot_buttons() -> void:
	# Insert 3 slot buttons after the Title label, before Info
	var center := $Center
	var insert_at := info.get_index()
	for slot in range(1, GameState.TOTAL_SLOTS + 1):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(280, 28)
		btn.text = _slot_button_text(slot)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_slot_pressed.bind(slot))
		center.add_child(btn)
		center.move_child(btn, insert_at)
		insert_at += 1
		slot_buttons.append(btn)

func _slot_button_text(slot: int) -> String:
	var snap: Dictionary = GameState.peek_slot(slot)
	if snap.is_empty():
		return "Slot %d:  (Empty)  — start new" % slot
	var t: int = int(snap["playtime_seconds"])
	var time_str: String = "%dm" % (t / 60) if t < 3600 else "%dh%02dm" % [t / 3600, (t % 3600) / 60]
	return "Slot %d:  %s  | Party %d  | Captures %d  | $%d" % [
		slot, time_str, int(snap["party_size"]), int(snap["captures"]), int(snap["money"]),
	]

func _on_slot_pressed(slot: int) -> void:
	GameState.set_slot(slot)
	if not GameState.load_game():
		GameState.new_game()
	Fade.go_to_scene("res://scenes/Overworld.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _on_slot_pressed(1)
			KEY_2: _on_slot_pressed(2)
			KEY_3: _on_slot_pressed(3)
			KEY_R:
				GameState.delete_all_saves()
				for i in slot_buttons.size():
					(slot_buttons[i] as Button).text = _slot_button_text(i + 1)
				info.text = "All save slots cleared."
