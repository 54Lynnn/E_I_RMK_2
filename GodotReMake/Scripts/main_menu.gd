extends Control

const MonsterDatabase = preload("res://Scripts/Monsters/monster_database.gd")

var quest_level_names := [
	"Ancient Way", "Burned Land", "Desert Battle", "Forgotten Dunes",
	"Dark Swamp", "Skull Coast", "Snowy Pass", "Hell Eye", "Inferno", "Diablo's Lair"
]

@onready var continue_button := $CenterContainer/VBoxContainer/ContinueButton
@onready var continue_info := $CenterContainer/VBoxContainer/ContinueInfo

func _ready():
	_connect_buttons()
	_update_continue_button()

func _connect_buttons():
	$CenterContainer/VBoxContainer/NewGameButton.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	$CenterContainer/VBoxContainer/HighScoresButton.pressed.connect(_on_high_scores)
	$CenterContainer/VBoxContainer/OptionsButton.pressed.connect(_on_options)
	$CenterContainer/VBoxContainer/ControlsButton.pressed.connect(_on_controls)
	$CenterContainer/VBoxContainer/CreditsButton.pressed.connect(_on_credits)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit)

func _update_continue_button():
	var save_info = SaveManager.get_save_info(2)
	if save_info.exists and save_info.has_quest_progress:
		continue_button.disabled = false
		continue_button.modulate = Color.WHITE
		var level_idx = save_info.quest_level
		var level_name = quest_level_names[level_idx] if level_idx >= 0 and level_idx < quest_level_names.size() else "Unknown"
		var hero_lvl = save_info.level
		continue_info.text = "Level %d - Quest %d (%s)" % [hero_lvl, level_idx + 1, level_name]
		continue_info.modulate = Color(0.7, 0.9, 1.0, 1.0)
	else:
		continue_button.disabled = true
		continue_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		continue_info.text = "No saved progress"
		continue_info.modulate = Color(0.5, 0.5, 0.5, 1.0)

func _on_new_game():
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

func _on_continue():
	var save_info = SaveManager.get_save_info(2)
	if not save_info.exists or not save_info.has_quest_progress:
		return
	var success = SaveManager.load_game(2)
	if not success:
		return
	Global.current_game_mode = Global.GameMode.QUEST
	Global.is_resuming_quest = true
	get_tree().change_scene_to_file("res://Scenes/LevelSelect.tscn")

func _on_high_scores():
	get_tree().change_scene_to_file("res://Scenes/HighScores.tscn")

func _on_options():
	get_tree().change_scene_to_file("res://Scenes/Options.tscn")

func _on_controls():
	get_tree().change_scene_to_file("res://Scenes/ControlsGuide.tscn")

func _on_credits():
	get_tree().change_scene_to_file("res://Scenes/Credits.tscn")

func _on_quit():
	get_tree().quit()
