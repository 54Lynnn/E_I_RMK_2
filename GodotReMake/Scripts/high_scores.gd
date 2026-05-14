extends Control

const SCORES_FILE := "user://high_scores.json"
const MAX_ENTRIES := 10

var current_tab := "survival"
var scores_data := {}

@onready var survival_tab := $CenterContainer/VBoxContainer/ModeTabs/SurvivalTab
@onready var quest_tab := $CenterContainer/VBoxContainer/ModeTabs/QuestTab
@onready var score_container := $CenterContainer/VBoxContainer/ScoreList/ScoreContainer
@onready var back_button := $CenterContainer/VBoxContainer/BackButton

func _ready():
	_load_scores()
	_connect_buttons()
	_show_tab("survival")

func _connect_buttons():
	survival_tab.pressed.connect(_on_survival_tab)
	quest_tab.pressed.connect(_on_quest_tab)
	back_button.pressed.connect(_on_back)

func _on_survival_tab():
	_show_tab("survival")

func _on_quest_tab():
	_show_tab("quest")

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _show_tab(tab: String):
	current_tab = tab
	survival_tab.disabled = (tab == "survival")
	quest_tab.disabled = (tab == "quest")
	_refresh_list()

func _refresh_list():
	for child in score_container.get_children():
		child.queue_free()

	var entries = scores_data.get(current_tab, [])
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No scores yet!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		empty_label.custom_minimum_size = Vector2(0, 60)
		score_container.add_child(empty_label)
		return

	var rank = 1
	for entry in entries:
		var row := HBoxContainer.new()

		var rank_label := Label.new()
		rank_label.text = "#%d" % rank
		rank_label.custom_minimum_size = Vector2(60, 28)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_font_size_override("font_size", 16)
		if rank == 1:
			rank_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
		elif rank == 2:
			rank_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1.0))
		elif rank == 3:
			rank_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.4, 1.0))
		else:
			rank_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		row.add_child(rank_label)

		var score_label := Label.new()
		score_label.text = str(entry.get("score", 0))
		score_label.custom_minimum_size = Vector2(120, 28)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.add_theme_font_size_override("font_size", 16)
		score_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		row.add_child(score_label)

		var level_label := Label.new()
		level_label.text = str(entry.get("level", 1))
		level_label.custom_minimum_size = Vector2(100, 28)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_font_size_override("font_size", 16)
		level_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		row.add_child(level_label)

		var date_label := Label.new()
		date_label.text = entry.get("date", "")
		date_label.custom_minimum_size = Vector2(120, 28)
		date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		date_label.add_theme_font_size_override("font_size", 14)
		date_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		row.add_child(date_label)

		score_container.add_child(row)
		rank += 1

func _load_scores():
	if not FileAccess.file_exists(SCORES_FILE):
		scores_data = {"survival": [], "quest": []}
		return
	var file := FileAccess.open(SCORES_FILE, FileAccess.READ)
	if file == null:
		scores_data = {"survival": [], "quest": []}
		return
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		scores_data = {"survival": [], "quest": []}
		return
	scores_data = json.data

func add_score(mode: String, score: int, level: int):
	_load_scores()
	var entries = scores_data.get(mode, [])
	var date_str = Time.get_date_string_from_system()
	entries.append({"score": score, "level": level, "date": date_str})
	entries.sort_custom(func(a, b): return a.score > b.score)
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	scores_data[mode] = entries
	_save_scores()

func _save_scores():
	var dir = DirAccess.open("user://")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("user://")
	var file := FileAccess.open(SCORES_FILE, FileAccess.WRITE)
	if file == null:
		return
	var json_text := JSON.stringify(scores_data, "\t", false, true)
	file.store_string(json_text)
	file.close()
