extends CanvasLayer

var mode := "quest"

@onready var background := $Background
@onready var title_label := $Background/CenterContainer/VBoxContainer/TitleLabel
@onready var stats_label := $Background/CenterContainer/VBoxContainer/StatsLabel
@onready var retry_button := $Background/CenterContainer/VBoxContainer/RetryButton
@onready var menu_button := $Background/CenterContainer/VBoxContainer/MenuButton

func _ready():
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_return_to_menu)

func _input(event):
	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()

func show_game_over(mode_name: String, stats: Dictionary):
	mode = mode_name
	var lines := []
	title_label.text = "GAME OVER" if mode_name == "quest" else "YOU DIED"

	if mode_name == "quest":
		var level_num = stats.get("level_number", 1)
		var level_name = stats.get("level_name", "Unknown")
		lines.append("Level %d - %s" % [level_num, level_name])
		lines.append("Monsters Killed: %d" % stats.get("monsters_killed", 0))
	elif mode_name == "survival":
		lines.append("Survival Mode")
		lines.append("Experience Gained: %d" % stats.get("experience_gained", 0))

	lines.append("Hero Level: %d" % stats.get("hero_level", 1))

	stats_label.text = "\n".join(lines)

	if mode_name == "quest":
		retry_button.text = "Retry Level"
	else:
		retry_button.text = "Restart"

	visible = true
	get_tree().paused = true

func _on_retry():
	get_tree().paused = false
	if mode == "quest":
		get_tree().reload_current_scene()
	else:
		Global.survival_total_exp_gained = 0
		Global.reset()
		Global.hero_level = 1
		Global.hero_experience = 0
		Global.attribute_points = 0
		Global.skill_points = 0
		get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_return_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")
