extends Control

# ============================================
# 关卡选择器
# 
# 功能：
# 1. 显示10个关卡按钮
# 2. 根据解锁状态启用/禁用按钮
# 3. 点击关卡进入 QuestMain 场景
# 4. 显示关卡信息（名称、状态）
# ============================================

# 关卡配置（从 quest_level_manager.gd 复制）
var level_configs := [
	{ "name": "Ancient Way",       "allowed_monsters": ["troll", "mummy"] },
	{ "name": "Burned Land",       "allowed_monsters": ["troll", "mummy", "spider"] },
	{ "name": "Desert Battle",     "allowed_monsters": ["troll", "mummy", "spider"] },
	{ "name": "Forgotten Dunes",   "allowed_monsters": ["troll", "mummy", "spider", "bear"] },
	{ "name": "Dark Swamp",        "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon"] },
	{ "name": "Skull Coast",       "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon"] },
	{ "name": "Snowy Pass",        "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon", "reaper"] },
	{ "name": "Hell Eye",          "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon", "reaper", "diablo"] },
	{ "name": "Inferno",           "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon", "reaper", "diablo"] },
	{ "name": "Diablo's Lair",     "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon", "reaper", "diablo"] }
]

# 按钮引用
var level_buttons := []

@onready var grid_container = $CenterContainer/VBoxContainer/GridContainer
@onready var back_button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	_create_level_buttons()
	_update_button_states()
	back_button.pressed.connect(_on_back_pressed)

func _create_level_buttons():
	"""创建10个关卡按钮"""
	for i in range(10):
		var button = Button.new()
		button.custom_minimum_size = Vector2(120, 80)
		button.text = "Level %d\n%s" % [i + 1, level_configs[i]["name"]]
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# 连接点击信号
		var level_index = i
		button.pressed.connect(func(): _on_level_selected(level_index))
		
		grid_container.add_child(button)
		level_buttons.append(button)

func _update_button_states():
	"""更新按钮状态（已解锁/未解锁）"""
	for i in range(10):
		var button = level_buttons[i]
		var is_unlocked = i <= Global.quest_max_unlocked_level
		
		button.disabled = not is_unlocked
		
		if is_unlocked:
			button.modulate = Color(1, 1, 1, 1)  # 正常颜色
			if i < Global.quest_max_unlocked_level:
				button.text = "Level %d\n%s\n[已完成]" % [i + 1, level_configs[i]["name"]]
			else:
				button.text = "Level %d\n%s\n[当前]" % [i + 1, level_configs[i]["name"]]
		else:
			button.modulate = Color(0.5, 0.5, 0.5, 1)
			button.text = "Level %d\n%s\n[锁定]" % [i + 1, level_configs[i]["name"]]

func _on_level_selected(level_index: int):
	Global.quest_progress.current_level = level_index
	Global.quest_progress.monsters_killed = 0
	Global.quest_progress.monsters_spawned = 0
	Global.quest_progress.has_progress = true
	
	# 如果不是第一关，设置起始等级为上一关结束时的等级
	if level_index > 0:
		# 这里需要从存档读取上一关结束时的等级
		# 暂时使用默认值
		Global.quest_progress.level_start_level = 1 + level_index * 4
	else:
		Global.quest_progress.level_start_level = 1
	
	# 进入 QuestMain 场景
	get_tree().change_scene_to_file("res://Scenes/QuestMain.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")
