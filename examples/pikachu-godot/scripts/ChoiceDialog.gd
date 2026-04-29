extends CanvasLayer

signal chosen(index: int)

var pending_title: String = ""
var pending_choices: Array = []

func set_data(title: String, choices: Array) -> void:
	pending_title = title
	pending_choices = choices

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	$Panel/V/Title.text = pending_title
	for i in pending_choices.size():
		var btn := Button.new()
		btn.text = String(pending_choices[i])
		btn.pressed.connect(_on_pressed.bind(i))
		$Panel/V.add_child(btn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# ESC = pick the last option (typically "skip" / "cancel")
		_on_pressed(pending_choices.size() - 1)
		get_viewport().set_input_as_handled()

func _on_pressed(idx: int) -> void:
	get_tree().paused = false
	chosen.emit(idx)
	queue_free()
