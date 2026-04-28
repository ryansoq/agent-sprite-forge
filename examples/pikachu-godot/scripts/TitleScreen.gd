extends Control

@onready var info: Label = $Center/Info
@onready var subtitle: Label = $Center/Subtitle

func _ready() -> void:
	if GameState.party.size() > 0:
		info.text = "Captures: %d   Party: %d" % [GameState.captures, GameState.party.size()]
		subtitle.text = "[Space] Continue   [R] Reset Save"
	else:
		info.text = "A new adventure awaits."
		subtitle.text = "[Space] Start"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		Fade.go_to_scene("res://scenes/Overworld.tscn")
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		GameState.delete_save()
		GameState.new_game()
		Fade.go_to_scene("res://scenes/Overworld.tscn")
