extends Control

# 预加载怪物数据库（用于获取难度名称）
const MonsterDatabase = preload("res://Scripts/Monsters/monster_database.gd")

# ============================================
# GameModeSelect.gd - 游戏主菜单
# ============================================
# 这是游戏的入口界面，玩家可以：
# 1. Resume Game - 继续上次Quest进度（如果有存档）
# 2. Start Game - 新游戏 → 选择 Quest / Survival
# 3. Quit - 退出游戏
#
# 流程：主菜单 → 模式选择 → 游戏主场景
# ============================================

# UI 引用
@onready var resume_button := $CenterContainer/VBoxContainer/ResumeButton
@onready var resume_info := $CenterContainer/VBoxContainer/ResumeInfo
@onready var game_mode_dropdown := $CenterContainer/VBoxContainer/ModeSection/GameModeDropdown
@onready var difficulty_dropdown := $CenterContainer/VBoxContainer/DifficultySection/DifficultyDropdown
@onready var start_button := $CenterContainer/VBoxContainer/StartButton
@onready var quit_button := $CenterContainer/VBoxContainer/QuitButton
@onready var quest_warning := $CenterContainer/VBoxContainer/ModeSection/QuestWarning

# 游戏主场景路径
const MAIN_SCENE_PATH := "res://Scenes/Main.tscn"
const QUEST_SCENE_PATH := "res://Scenes/QuestMain.tscn"

# Quest 关卡名称（用于显示）
var level_names := [
	"Ancient Way", "Burned Land", "Desert Battle", "Forgotten Dunes",
	"Dark Swamp", "Skull Coast", "Snowy Pass", "Hell Eye", "Inferno", "Diablo's Lair"
]

func _ready():
	# 初始化下拉菜单
	_setup_game_mode_dropdown()
	_setup_difficulty_dropdown()
	
	# 连接信号
	resume_button.pressed.connect(_on_resume_game)
	game_mode_dropdown.item_selected.connect(_on_game_mode_changed)
	difficulty_dropdown.item_selected.connect(_on_difficulty_changed)
	start_button.pressed.connect(_on_start_game)
	quit_button.pressed.connect(_on_quit_game)
	
	# 默认选择
	game_mode_dropdown.select(1)  # Survival
	difficulty_dropdown.select(0)  # Normal
	
	# 隐藏 Quest 警告
	quest_warning.visible = false
	
	# 检查是否有可恢复的存档
	_update_resume_button()

# ============================================
# Resume Game 功能
# ============================================

func _update_resume_button():
	"""更新 Resume Game 按钮状态"""
	# Quest 自动存档使用槽位2
	var save_info = SaveManager.get_save_info(2)
	
	if save_info.exists and save_info.has_quest_progress:
		# 有 Quest 进度，启用按钮并显示信息
		resume_button.disabled = false
		resume_button.modulate = Color.WHITE
		
		var level_idx = save_info.quest_level
		var level_name = level_names[level_idx] if level_idx >= 0 and level_idx < level_names.size() else "Unknown"
		var hero_level = save_info.level
		
		resume_info.text = "Resume - Level %d (Quest %d-%s)" % [hero_level, level_idx + 1, level_name]
		resume_info.modulate = Color(0.7, 0.9, 1.0, 1.0)
	else:
		# 没有存档，禁用按钮
		resume_button.disabled = true
		resume_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		resume_info.text = "No saved progress"
		resume_info.modulate = Color(0.5, 0.5, 0.5, 1.0)

func _on_resume_game():
	"""继续上次 Quest 进度"""
	# Quest 自动存档使用槽位2
	var save_info = SaveManager.get_save_info(2)
	
	if not save_info.exists or not save_info.has_quest_progress:
		print("Resume: 没有可恢复的进度")
		return
	
	print("Resume: 正在恢复 Quest 进度...")
	
	# 1. 读取存档（这会加载 Global.quest_progress）
	# Quest 自动存档使用槽位2
	var success = SaveManager.load_game(2)
	if not success:
		push_error("Resume: 读取存档失败")
		return
	
	# 2. 确保是 Quest 模式
	Global.current_game_mode = Global.GameMode.QUEST
	
	# 3. 设置标志，告诉 QuestLevelManager 这是 Resume 模式
	Global.is_resuming_quest = true
	
	# 4. 切换到关卡选择器（Resume时也从选择器开始，但保留进度）
	get_tree().change_scene_to_file("res://Scenes/LevelSelect.tscn")

# ============================================
# 设置下拉菜单
# ============================================
func _setup_game_mode_dropdown():
	game_mode_dropdown.clear()
	game_mode_dropdown.add_item("Quest", 0)
	game_mode_dropdown.add_item("Survival", 1)

func _setup_difficulty_dropdown():
	difficulty_dropdown.clear()
	difficulty_dropdown.add_item("Normal", 0)
	difficulty_dropdown.add_item("Nightmare", 1)
	difficulty_dropdown.add_item("Hardcore", 2)

# ============================================
# 游戏模式改变
# ============================================
func _on_game_mode_changed(index: int):
	if index == 0:
		quest_warning.visible = true
		quest_warning.text = "Quest Mode: Progress through 10 levels!"
		quest_warning.modulate = Color.GREEN
	else:
		quest_warning.visible = true
		quest_warning.text = "Survival Mode: Fight until you die!"
		quest_warning.modulate = Color.YELLOW

# ============================================
# 难度改变
# ============================================
func _on_difficulty_changed(index: int):
	var difficulty_name = difficulty_dropdown.get_item_text(index)
	print("Selected difficulty: " + difficulty_name)

# ============================================
# 开始游戏
# ============================================
func _on_start_game():
	# 获取选择的游戏模式
	var mode_index = game_mode_dropdown.selected
	var selected_mode = Global.GameMode.QUEST if mode_index == 0 else Global.GameMode.SURVIVAL
	
	# 获取选择的难度
	var difficulty_index = difficulty_dropdown.selected
	var selected_difficulty: int
	match difficulty_index:
		0: selected_difficulty = Global.Difficulty.NORMAL
		1: selected_difficulty = Global.Difficulty.NIGHTMARE
		2: selected_difficulty = Global.Difficulty.HARDCORE
		_: selected_difficulty = Global.Difficulty.NORMAL
	
	# 保存到全局
	Global.current_game_mode = selected_mode
	Global.current_difficulty = selected_difficulty
	
	# 清除之前的 Quest 进度（新游戏）
	Global.quest_progress.has_progress = false
	Global.quest_progress.current_level = 0
	Global.quest_progress.monsters_killed = 0
	Global.quest_progress.monsters_spawned = 0
	Global.quest_progress.level_start_level = 1
	
	# 新游戏：重置英雄等级为1（Quest模式）
	if selected_mode == Global.GameMode.QUEST:
		print("Quest: 重置前 - hero_level=%d" % Global.hero_level)
		Global.hero_level = 1
		Global.hero_experience = 0
		Global.attribute_points = 0
		Global.skill_points = 0
		print("Quest: 新游戏，重置英雄等级为1")
	
	print("Starting game with mode: %s, difficulty: %s" % [
		"Quest" if selected_mode == Global.GameMode.QUEST else "Survival",
		MonsterDatabase.get_difficulty_name(selected_difficulty)
	])
	
	# 根据模式切换到对应场景
	if selected_mode == Global.GameMode.QUEST:
		# Quest模式：先进入关卡选择器
		get_tree().change_scene_to_file("res://Scenes/LevelSelect.tscn")
	else:
		get_tree().change_scene_to_file(MAIN_SCENE_PATH)

# ============================================
# 退出游戏
# ============================================
func _on_quit_game():
	get_tree().quit()
