extends Control

@onready var menu_button := $CenterContainer/VBoxContainer/MenuButton

func _ready():
	menu_button.pressed.connect(_on_return_to_menu)
	_display_stats()
	_clear_quest_progress()

func _clear_quest_progress():
	Global.quest_progress.has_progress = false
	Global.quest_progress.current_level = 0
	Global.quest_progress.monsters_killed = 0
	Global.quest_progress.monsters_spawned = 0
	Global.quest_max_unlocked_level = 0
	var success = SaveManager.save_game(2)
	if success:
		print("VictoryScreen: Quest 进度已清除")

func _display_stats():
	var stats_label = $CenterContainer/VBoxContainer/StatsLabel
	var total_kills = Global.quest_total_monsters_killed
	stats_label.text = "Total Monsters Killed: %d\nFinal Hero Level: %d\n\nCongratulations!" % [total_kills, Global.hero_level]

func _input(event):
	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()

func _on_return_to_menu():
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")
