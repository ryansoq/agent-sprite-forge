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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_resume()
		get_viewport().set_input_as_handled()

func _resume() -> void:
	get_tree().paused = false
	queue_free()

func _save() -> void:
	GameState.save_game()
	$Panel/V/Status.text = "Saved."

func _to_title() -> void:
	GameState.save_game()
	get_tree().paused = false
	Fade.go_to_scene("res://scenes/TitleScreen.tscn")
