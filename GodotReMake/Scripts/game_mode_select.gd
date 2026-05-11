extends Control

# 预加载怪物数据库（用于获取难度名称）
const MonsterDatabase = preload("res://Scripts/Monsters/monster_database.gd")

# ============================================
# GameModeSelect.gd - 游戏模式和难度选择界面
# ============================================
# 这是游戏的入口界面，玩家可以：
# 1. 选择游戏模式（Quest/Survival）
# 2. 选择难度（Normal/Nightmare/Hardcore）
# 3. 点击 Start Game 开始游戏
#
# 流程：主菜单 → 模式选择 → 游戏主场景
# ============================================

# UI 引用
@onready var game_mode_dropdown := $CenterContainer/VBoxContainer/ModeSection/GameModeDropdown
@onready var difficulty_dropdown := $CenterContainer/VBoxContainer/DifficultySection/DifficultyDropdown
@onready var start_button := $CenterContainer/VBoxContainer/StartButton
@onready var quest_warning := $CenterContainer/VBoxContainer/ModeSection/QuestWarning

# 游戏主场景路径
const MAIN_SCENE_PATH := "res://Scenes/Main.tscn"
const QUEST_SCENE_PATH := "res://Scenes/QuestMain.tscn"

func _ready():
	# 初始化下拉菜单
	_setup_game_mode_dropdown()
	_setup_difficulty_dropdown()
	
	# 连接信号
	game_mode_dropdown.item_selected.connect(_on_game_mode_changed)
	difficulty_dropdown.item_selected.connect(_on_difficulty_changed)
	start_button.pressed.connect(_on_start_game)
	
	# 默认选择
	game_mode_dropdown.select(1)  # Survival
	difficulty_dropdown.select(0)  # Normal
	
	# 隐藏 Quest 警告
	quest_warning.visible = false

# ============================================
# 设置游戏模式下拉菜单
# ============================================
func _setup_game_mode_dropdown():
	game_mode_dropdown.clear()
	game_mode_dropdown.add_item("Quest", 0)
	game_mode_dropdown.add_item("Survival", 1)
	
	# 设置 Quest 为灰色（不可用）
	# 注意：Godot 4 的 OptionButton 不直接支持禁用单个选项
	# 我们通过选择后自动切换来处理

# ============================================
# 设置难度下拉菜单
# ============================================
func _setup_difficulty_dropdown():
	difficulty_dropdown.clear()
	difficulty_dropdown.add_item("Normal", 0)
	difficulty_dropdown.add_item("Nightmare", 1)
	difficulty_dropdown.add_item("Hardcore", 2)

# ============================================
# 游戏模式改变
# ============================================
func _on_game_mode_changed(index: int):
	# Quest模式现在可用
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
	# 可以在这里预览难度效果
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
	
	print("Starting game with mode: %s, difficulty: %s" % [
		"Quest" if selected_mode == Global.GameMode.QUEST else "Survival",
		MonsterDatabase.get_difficulty_name(selected_difficulty)
	])
	
	# 根据模式切换到对应场景
	if selected_mode == Global.GameMode.QUEST:
		get_tree().change_scene_to_file(QUEST_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(MAIN_SCENE_PATH)
