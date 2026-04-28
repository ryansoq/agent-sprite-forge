extends CanvasLayer

@onready var resume_btn: Button = $Panel/V/ResumeButton
@onready var save_btn: Button = $Panel/V/SaveButton
@onready var title_btn: Button = $Panel/V/TitleButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	resume_btn.pressed.connect(_resume)
	save_btn.pressed.connect(_save)
	title_btn.pressed.connect(_to_title)
	$Panel/V/Status.text = _summary_text()

func _summary_text() -> String:
	var t: int = int(GameState.playtime_seconds)
	var h: int = t / 3600
	var m: int = (t % 3600) / 60
	var s: int = t % 60
	var time_str: String = ("%dh %02dm" % [h, m]) if h > 0 else ("%dm %02ds" % [m, s])
	return "%s   |   Party: %d   |   Captured: %d   |   $%d" % [
		time_str, GameState.party.size(), GameState.captures, GameState.money,
	]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_resume()
		get_viewport().set_input_as_handled()

func _resume() -> void:
	get_tree().paused = false
	queue_free()

func _save() -> void:
	GameState.save_game()
	$Panel/V/Status.text = "Saved.   " + _summary_text()

func _to_title() -> void:
	GameState.save_game()
	get_tree().paused = false
	Fade.go_to_scene("res://scenes/TitleScreen.tscn")
