extends Control

# ============================================
# QuestHUDManager.gd - Quest模式HUD管理器
# ============================================
# 显示Quest模式特有的信息：
# 1. 当前关卡名称和编号
# 2. 剩余怪物数量
# 3. 等级上限提示
# 4. 关卡完成提示
# ============================================

# UI元素（在_setup_ui中初始化）
var level_label: Label = null
var monster_label: Label = null
var level_up_warning: Label = null
var level_complete_panel: Panel = null
var all_complete_panel: Panel = null

# 引用
var level_manager: Node = null

func _ready():
	# 查找关卡管理器
	await get_tree().process_frame
	level_manager = get_tree().get_first_node_in_group("quest_level_manager")
	
	if level_manager:
		# 连接信号
		level_manager.level_started.connect(_on_level_started)
		level_manager.level_completed.connect(_on_level_completed)
		level_manager.all_levels_completed.connect(_on_all_levels_completed)
		level_manager.monster_count_changed.connect(_on_monster_count_changed)
		level_manager.level_up_limited.connect(_on_level_up_limited)
	else:
		push_warning("QuestHUDManager: 未找到QuestLevelManager！")
	
	# 初始化UI
	_setup_ui()

func _setup_ui():
	"""初始化UI元素"""
	# 创建关卡信息面板
	var level_info = Control.new()
	level_info.name = "LevelInfo"
	level_info.anchor_left = 0.5
	level_info.anchor_right = 0.5
	level_info.offset_left = -150
	level_info.offset_right = 150
	level_info.offset_top = 10
	level_info.offset_bottom = 100
	add_child(level_info)
	
	# 关卡标签
	var level_label_node = Label.new()
	level_label_node.name = "LevelLabel"
	level_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label_node.add_theme_font_size_override("font_size", 20)
	level_label_node.add_theme_color_override("font_color", Color.GOLD)
	level_info.add_child(level_label_node)
	level_label = level_label_node
	
	# 怪物数量标签
	var monster_label_node = Label.new()
	monster_label_node.name = "MonsterLabel"
	monster_label_node.position = Vector2(0, 30)
	monster_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monster_label_node.add_theme_font_size_override("font_size", 16)
	level_info.add_child(monster_label_node)
	monster_label = monster_label_node
	
	# 等级上限警告
	var warning_label = Label.new()
	warning_label.name = "LevelUpWarning"
	warning_label.position = Vector2(0, 55)
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.add_theme_font_size_override("font_size", 14)
	warning_label.add_theme_color_override("font_color", Color.RED)
	warning_label.visible = false
	level_info.add_child(warning_label)
	level_up_warning = warning_label
	
	# 关卡完成面板
	var complete_panel = Panel.new()
	complete_panel.name = "LevelCompletePanel"
	complete_panel.anchor_left = 0.5
	complete_panel.anchor_top = 0.5
	complete_panel.anchor_right = 0.5
	complete_panel.anchor_bottom = 0.5
	complete_panel.offset_left = -200
	complete_panel.offset_top = -100
	complete_panel.offset_right = 200
	complete_panel.offset_bottom = 100
	complete_panel.visible = false
	add_child(complete_panel)
	level_complete_panel = complete_panel
	
	var complete_label = Label.new()
	complete_label.text = "Level Complete!"
	complete_label.anchor_left = 0.5
	complete_label.anchor_top = 0.5
	complete_label.anchor_right = 0.5
	complete_label.anchor_bottom = 0.5
	complete_label.offset_left = -100
	complete_label.offset_top = -20
	complete_label.offset_right = 100
	complete_label.offset_bottom = 20
	complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	complete_label.add_theme_font_size_override("font_size", 32)
	complete_label.add_theme_color_override("font_color", Color.GREEN)
	complete_panel.add_child(complete_label)
	
	# 全部完成面板
	var all_panel = Panel.new()
	all_panel.name = "AllCompletePanel"
	all_panel.anchor_left = 0.5
	all_panel.anchor_top = 0.5
	all_panel.anchor_right = 0.5
	all_panel.anchor_bottom = 0.5
	all_panel.offset_left = -250
	all_panel.offset_top = -150
	all_panel.offset_right = 250
	all_panel.offset_bottom = 150
	all_panel.visible = false
	add_child(all_panel)
	all_complete_panel = all_panel
	
	var all_label = Label.new()
	all_label.text = "Quest Complete!\nYou have conquered all 10 levels!"
	all_label.anchor_left = 0.5
	all_label.anchor_top = 0.5
	all_label.anchor_right = 0.5
	all_label.anchor_bottom = 0.5
	all_label.offset_left = -200
	all_label.offset_top = -50
	all_label.offset_right = 200
	all_label.offset_bottom = 50
	all_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	all_label.add_theme_font_size_override("font_size", 28)
	all_label.add_theme_color_override("font_color", Color.GOLD)
	all_panel.add_child(all_label)

# ============================================
# 信号处理
# ============================================

func _on_level_started(level_number: int, level_name: String):
	"""关卡开始"""
	level_label.text = "Level %d: %s" % [level_number, level_name]
	level_complete_panel.visible = false
	level_up_warning.visible = false

func _on_monster_count_changed(remaining: int, total: int):
	"""怪物数量变化"""
	monster_label.text = "Monsters: %d / %d" % [remaining, total]

func _on_level_completed(level_number: int):
	"""关卡完成"""
	level_complete_panel.visible = true
	await get_tree().create_timer(1.5).timeout
	level_complete_panel.visible = false

func _on_all_levels_completed():
	"""全部关卡完成"""
	all_complete_panel.visible = true
	get_tree().paused = true

func _on_level_up_limited(max_level: int):
	"""达到等级上限"""
	level_up_warning.text = "Level Cap Reached! (Max: %d)" % max_level
	level_up_warning.visible = true
