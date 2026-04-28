extends CanvasLayer

signal closed

@onready var label: Label = $Panel/Label
@onready var hint: Label = $Panel/Hint

var pages: Array = []
var idx: int = 0

func set_dialogue_pages(p: Array) -> void:
	pages = p
	idx = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_show_page()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()

func _show_page() -> void:
	if idx >= pages.size():
		_close()
		return
	label.text = String(pages[idx])
	hint.text = "[Space] %s" % ("Continue" if idx < pages.size() - 1 else "Close")

func _advance() -> void:
	idx += 1
	_show_page()

func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
