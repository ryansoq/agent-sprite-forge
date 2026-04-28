extends Node

# Define semantic input actions at boot so scripts can use named actions
# instead of relying on ui_accept/ui_cancel.

func _ready() -> void:
	_ensure("interact", [KEY_SPACE, KEY_ENTER])
	_ensure("pause",    [KEY_ESCAPE])

func _ensure(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.keycode = k
		InputMap.action_add_event(action, ev)
