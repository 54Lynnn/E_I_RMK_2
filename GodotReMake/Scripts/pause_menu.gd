extends CanvasLayer

var is_open := false

@onready var background := $Background
@onready var buttons_container := $Background/CenterContainer/VBoxContainer

func _ready():
	visible = false
	Global.is_pause_menu_open = false
	_connect_buttons()

func _connect_buttons():
	var resume_btn = buttons_container.get_node("ResumeButton")
	var save_btn = buttons_container.get_node("SaveButton")
	var load_btn = buttons_container.get_node("LoadButton")
	var menu_btn = buttons_container.get_node("MenuButton")
	var quit_btn = buttons_container.get_node("QuitButton")

	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	menu_btn.pressed.connect(_on_return_to_menu)
	quit_btn.pressed.connect(_on_quit)

	_check_save_exists(load_btn)

func _check_save_exists(load_btn: Button):
	var save_info = SaveManager.get_save_info(1)
	load_btn.disabled = not save_info.exists
	if not save_info.exists:
		load_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		load_btn.modulate = Color.WHITE

func _input(event):
	if event.is_action_pressed("pause_game"):
		if is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()

func open():
	if Global.hero_panel_is_open:
		return
	is_open = true
	Global.is_pause_menu_open = true
	visible = true
	get_tree().paused = true

func close():
	is_open = false
	Global.is_pause_menu_open = false
	visible = false
	get_tree().paused = false

func _on_resume():
	close()

func _on_save():
	var hero = get_tree().get_first_node_in_group("hero")
	if hero and hero.has_method("_save_game"):
		hero._save_game()
	else:
		Global.hero_save_position = Vector2.ZERO
		var success = SaveManager.save_game(1)
		if success:
			_show_feedback("Game Saved!", Color.GREEN)
		else:
			_show_feedback("Save Failed!", Color.RED)

func _on_load():
	_show_feedback("Loading...", Color.CYAN)
	close()
	var hero = get_tree().get_first_node_in_group("hero")
	if hero and hero.has_method("_load_game"):
		hero._load_game()

func _on_return_to_menu():
	get_tree().paused = false
	Global.is_pause_menu_open = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_quit():
	get_tree().paused = false
	get_tree().quit()

func _show_feedback(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(312, 300)
	label.size = Vector2(400, 60)
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(label.queue_free)
