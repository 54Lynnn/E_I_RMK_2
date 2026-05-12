extends CanvasLayer

var level_index := 0
var is_last_level := false

@onready var background := $Background
@onready var title_label := $Background/CenterContainer/VBoxContainer/TitleLabel
@onready var stats_label := $Background/CenterContainer/VBoxContainer/StatsLabel
@onready var continue_button := $Background/CenterContainer/VBoxContainer/ContinueButton

func _ready():
	continue_button.pressed.connect(_on_continue)

func _input(event):
	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()

func show_level_complete(level_num: int, level_name: String, stats: Dictionary, is_last: bool = false):
	level_index = level_num - 1
	is_last_level = is_last

	title_label.text = "LEVEL CLEAR!"
	var lvl_info = "Level %d - %s" % [level_num, level_name]
	var kill_info = "Monsters Killed: %d" % stats.get("monsters_killed", 0)
	var hero_info = "Hero Level: %d" % stats.get("hero_level", 1)

	stats_label.text = "%s\n%s\n%s" % [lvl_info, kill_info, hero_info]

	if is_last:
		continue_button.text = "See Results"
	else:
		continue_button.text = "Continue"

	visible = true
	get_tree().paused = true

func _on_continue():
	get_tree().paused = false
	if is_last_level:
		get_tree().change_scene_to_file("res://Scenes/VictoryScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/LevelSelect.tscn")
