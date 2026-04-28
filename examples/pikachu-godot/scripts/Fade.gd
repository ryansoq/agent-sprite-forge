extends CanvasLayer

const DURATION := 0.25

var rect: ColorRect

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

func go_to_scene(path: String) -> void:
	await fade_out()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_in()

func fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(rect, "modulate:a", 1.0, DURATION)
	await tw.finished

func fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, DURATION)
	await tw.finished
