extends Node

# Define semantic input actions at boot so scripts can use named actions
# instead of relying on ui_accept/ui_cancel.

func _ready() -> void:
	_ensure("interact",     [KEY_SPACE, KEY_ENTER])
	_ensure("pause",        [KEY_ESCAPE])
	_ensure("fast_forward", [KEY_Z])
	# Append WASD to the directional actions alongside the arrow keys.
	_append_to("ui_left",  [KEY_A])
	_append_to("ui_right", [KEY_D])
	_append_to("ui_up",    [KEY_W])
	_append_to("ui_down",  [KEY_S])

func _ensure(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.keycode = k
		InputMap.action_add_event(action, ev)

func _append_to(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		return
	for k in keys:
		var ev := InputEventKey.new()
		ev.keycode = k
		InputMap.action_add_event(action, ev)
