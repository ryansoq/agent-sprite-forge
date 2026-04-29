extends CanvasLayer

func _ready() -> void:
	# Always-process so it works while opener (e.g. PauseMenu) has paused
	# the tree. Does NOT toggle tree.paused itself — the opener keeps that.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
		_close()
		get_viewport().set_input_as_handled()

func _build() -> void:
	var captured_ids := {}
	for m in GameState.party:
		captured_ids[String(m["id"])] = true
	$Panel/V/Summary.text = "Seen %d/%d   Caught %d" % [
		GameState.seen_species.size(),
		MonsterData.MONSTERS.size(),
		captured_ids.size(),
	]
	var grid: GridContainer = $Panel/V/Grid
	for species_id in MonsterData.MONSTERS.keys():
		var sid := String(species_id)
		var seen: bool = sid in GameState.seen_species
		var captured: bool = captured_ids.has(sid)

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(216, 36)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if seen:
			icon.texture = load(MonsterData.MONSTERS[sid]["sprite"])
		else:
			icon.modulate = Color(0, 0, 0, 0.6)
			icon.texture = load(MonsterData.MONSTERS[sid]["sprite"])  # silhouette
		row.add_child(icon)

		var label := Label.new()
		label.custom_minimum_size = Vector2(176, 32)
		label.add_theme_font_size_override("font_size", 11)
		if seen:
			var data: Dictionary = MonsterData.MONSTERS[sid]
			var marker: String = "  *" if captured else ""
			label.text = "%s%s\n%s" % [data["display_name"], marker, data["type"]]
		else:
			label.text = "???\n???"
		row.add_child(label)
		grid.add_child(row)

func _close() -> void:
	queue_free()
