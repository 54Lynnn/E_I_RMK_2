extends Control

func _ready():
	_add_content()

func _add_content():
	var panel = $CenterContainer/Panel
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "CONTROLS"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.color = Color(0.55, 0.35, 0.15, 0.6)
	vbox.add_child(divider)

	vbox.add_child(Control.new())

	var sections := [
		{"header": "MOVEMENT", "items": [
			{"key": "W/A/S/D", "desc": "Move hero up/left/down/right"},
			{"key": "Mouse", "desc": "Aim - hero faces the cursor"},
		]},
		{"header": "COMBAT", "items": [
			{"key": "LMB (hold)", "desc": "Cast left quick slot skill (default: Magic Missile)"},
			{"key": "RMB (hold)", "desc": "Cast right quick slot skill (default: Fireball)"},
			{"key": "Shift (hold)", "desc": "Cast shift quick slot skill (default: Freezing Spear)"},
			{"key": "Space (hold)", "desc": "Cast space quick slot skill (default: Heal)"},
		]},
		{"header": "QUICK SLOTS", "items": [
			{"key": "T / F2", "desc": "Open Hero Panel (pause game)"},
			{"key": "Right-click skill icon", "desc": "Set skill to a quick slot (LMB/RMB/Shift/Space)"},
			{"key": "Middle-click skill icon", "desc": "Toggle auto-cast for that skill"},
		]},
		{"header": "INTERFACE", "items": [
			{"key": "ESC", "desc": "Pause menu"},
			{"key": "T / F2", "desc": "Hero Panel - level up attributes and skills"},
			{"key": "ALT (hold)", "desc": "Show monster health bars and damage numbers"},
			{"key": "F4", "desc": "Toggle fullscreen"},
		]},
	]

	for section in sections:
		var header_label := Label.new()
		header_label.text = section.header
		header_label.add_theme_font_size_override("font_size", 22)
		header_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 1.0))
		vbox.add_child(header_label)

		for item in section.items:
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 12)

			var key_label := Label.new()
			key_label.text = item.key
			key_label.add_theme_font_size_override("font_size", 16)
			key_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5, 1.0))
			key_label.custom_minimum_size = Vector2(180, 0)
			row.add_child(key_label)

			var desc_label := Label.new()
			desc_label.text = item.desc
			desc_label.add_theme_font_size_override("font_size", 16)
			desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(desc_label)

			vbox.add_child(row)

		vbox.add_child(Control.new())

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(bottom_spacer)

	var close_btn := Button.new()
	close_btn.text = "Back"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.custom_minimum_size = Vector2(0, 44)
	close_btn.add_theme_font_size_override("font_size", 18)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.2, 0.1, 1.0)
	btn_style.border_color = Color(0.55, 0.35, 0.15, 1.0)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	close_btn.add_theme_stylebox_override("normal", btn_style)
	close_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	close_btn.pressed.connect(_on_back)
	vbox.add_child(close_btn)

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
