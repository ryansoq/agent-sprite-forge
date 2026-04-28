extends Node

# Apply a single Theme to the root viewport so every Panel / Label /
# Control inherits a consistent dark-green RPG style without per-scene
# overrides.

func _ready() -> void:
	var theme := Theme.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.16, 0.13, 0.92)
	panel_style.border_color = Color(0.45, 0.65, 0.50, 1.0)
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 3
	panel_style.corner_radius_top_right = 3
	panel_style.corner_radius_bottom_left = 3
	panel_style.corner_radius_bottom_right = 3
	panel_style.content_margin_left = 4
	panel_style.content_margin_right = 4
	panel_style.content_margin_top = 2
	panel_style.content_margin_bottom = 2
	theme.set_stylebox("panel", "Panel", panel_style)

	theme.set_color("font_color", "Label", Color(0.92, 0.95, 0.92))

	get_tree().root.theme = theme
