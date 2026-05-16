extends Control

const MonsterDatabase = preload("res://Scripts/Monsters/monster_database.gd")

@onready var game_mode_dropdown := $CenterContainer/VBoxContainer/ModeSection/GameModeDropdown
@onready var difficulty_dropdown := $CenterContainer/VBoxContainer/DifficultySection/DifficultyDropdown
@onready var start_button := $CenterContainer/VBoxContainer/StartButton
@onready var back_button := $CenterContainer/VBoxContainer/BackButton
@onready var quest_warning := $CenterContainer/VBoxContainer/ModeSection/QuestWarning

const MAIN_SCENE_PATH := "res://Scenes/Main.tscn"

func _ready():
	_setup_game_mode_dropdown()
	_setup_difficulty_dropdown()

	game_mode_dropdown.item_selected.connect(_on_game_mode_changed)
	difficulty_dropdown.item_selected.connect(_on_difficulty_changed)
	start_button.pressed.connect(_on_start_game)
	back_button.pressed.connect(_on_back)

	game_mode_dropdown.select(1)
	difficulty_dropdown.select(0)

	quest_warning.visible = false

func _setup_game_mode_dropdown():
	game_mode_dropdown.clear()
	game_mode_dropdown.add_item("Quest", 0)
	game_mode_dropdown.add_item("Survival", 1)

func _setup_difficulty_dropdown():
	difficulty_dropdown.clear()
	difficulty_dropdown.add_item("Normal", 0)
	difficulty_dropdown.add_item("Nightmare", 1)
	difficulty_dropdown.add_item("Hardcore", 2)

func _on_game_mode_changed(index: int):
	if index == 0:
		quest_warning.visible = true
		quest_warning.text = "Quest Mode: Progress through 10 levels!"
		quest_warning.modulate = Color.GREEN
	else:
		quest_warning.visible = true
		quest_warning.text = "Survival Mode: Fight until you die!"
		quest_warning.modulate = Color.YELLOW

func _on_difficulty_changed(index: int):
	pass

func _on_start_game():
	var mode_index = game_mode_dropdown.selected
	var selected_mode = Global.GameMode.QUEST if mode_index == 0 else Global.GameMode.SURVIVAL

	var difficulty_index = difficulty_dropdown.selected
	var selected_difficulty: int
	match difficulty_index:
		0: selected_difficulty = Global.Difficulty.NORMAL
		1: selected_difficulty = Global.Difficulty.NIGHTMARE
		2: selected_difficulty = Global.Difficulty.HARDCORE
		_: selected_difficulty = Global.Difficulty.NORMAL

	Global.current_game_mode = selected_mode
	Global.current_difficulty = selected_difficulty

	Global.quest_progress.has_progress = false
	Global.quest_progress.current_level = 0
	Global.quest_progress.monsters_killed = 0
	Global.quest_progress.monsters_spawned = 0
	Global.quest_progress.level_start_level = 1
	Global.quest_total_monsters_killed = 0

	if selected_mode == Global.GameMode.QUEST:
		Global.hero_level = 1
		Global.hero_experience = 0
		Global.attribute_points = 0
		Global.skill_points = 0

	if selected_mode == Global.GameMode.SURVIVAL:
		Global.survival_total_exp_gained = 0

	if selected_mode == Global.GameMode.QUEST:
		get_tree().change_scene_to_file("res://Scenes/LevelSelect.tscn")
	else:
		get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
