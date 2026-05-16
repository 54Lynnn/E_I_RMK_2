extends Node

# ============================================
# QuestLevelManager.gd - Quest模式关卡管理器
# ============================================
# 管理Quest模式的10个关卡：
# 1. 跟踪当前关卡进度
# 2. 管理每关的怪物生成和通关条件
# 3. 处理等级上限（每关最多升4级）
# 4. 检测通关条件（清除所有怪物）
# ============================================

# 信号
signal level_started(level_number, level_name)      # 关卡开始
signal level_completed(level_number)                 # 关卡完成
signal all_levels_completed                          # 全部10关完成
signal monster_count_changed(remaining, total)       # 剩余怪物数变化
signal level_up_limited(max_level)                   # 达到等级上限提示

# 关卡配置数据
# 每关包含：关卡名称、允许出现的怪物类型
# 设计思路：逐渐引入新怪物，后期关卡包含所有怪物
var level_configs := [
	{ "name": "Ancient Way",       "allowed_monsters": ["troll", "mummy"], "texture": "res://Art/Textures/map_tex_0_1024x1024.dds" },
	{ "name": "Burned Land",       "allowed_monsters": ["troll", "mummy", "spider"], "texture": "res://Art/Textures/map_tex_1_1024x1024.dds" },
	{ "name": "Desert Battle",     "allowed_monsters": ["troll", "mummy", "spider"], "texture": "res://Art/Textures/map_tex_2_1024x1024.dds" },
	{ "name": "Forgotten Dunes",   "allowed_monsters": ["troll", "mummy", "spider", "bear"], "texture": "res://Art/Textures/map_tex_3_1024x1024.dds" },
	{ "name": "Dark Swamp",        "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon"], "texture": "res://Art/Textures/map_tex_4_1024x1024.dds" },
	{ "name": "Skull Coast",       "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon"], "texture": "res://Art/Textures/map_tex_5_1024x1024.dds" },
	{ "name": "Snowy Pass",        "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon", "reaper"], "texture": "res://Art/Textures/map_tex_0_1024x1024.dds" },
	{ "name": "Hell Eye",          "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon", "reaper", "diablo"], "texture": "res://Art/Textures/map_tex_1_1024x1024.dds" },
	{ "name": "Inferno",           "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon", "reaper", "diablo"], "texture": "res://Art/Textures/map_tex_2_1024x1024.dds" },
	{ "name": "Diablo's Lair",     "allowed_monsters": ["troll", "mummy", "spider", "bear", "demon", "reaper", "diablo"], "texture": "res://Art/Textures/map_tex_3_1024x1024.dds" }
]

# 当前状态
var current_level := 0          # 当前关卡索引（0-9）
var monsters_killed := 0        # 本关已击杀怪物数
var monsters_spawned := 0       # 本关已生成怪物数
var is_level_active := false    # 当前是否在进行中
var is_completing_level := false # 防止complete_level重复调用
var level_start_level := 1      # 进入本关时的玩家等级

# 等级上限系统 - 改为基于本关内获取的总经验值
# 每关经验上限：Level 1: 2000, Level 2: 5200, Level 3: 8400, ...
# 计算方式：每关4级，每级需要 等级×200 经验
const LEVEL_EXP_REQUIREMENTS := [
	2000,   # Level 1: 200+400+600+800
	5200,   # Level 2: 1000+1200+1400+1600
	8400,   # Level 3: 1800+2000+2200+2400
	11600,  # Level 4: 2600+2800+3000+3200
	14800,  # Level 5: 3400+3600+3800+4000
	18000,  # Level 6: 4200+4400+4600+4800
	21200,  # Level 7: 5000+5200+5400+5600
	24400,  # Level 8: 5800+6000+6200+6400
	27600,  # Level 9: 6600+6800+7000+7200
	30800   # Level 10: 7400+7600+7800+8000
]
var is_level_cap_reached := false # 是否已达到等级上限
var level_experience_gained := 0  # 本关内获取的总经验值（减半前）

# 引用
@onready var spawner := $QuestMonsterSpawner

func _ready():
	# 等待场景准备好
	await get_tree().process_frame
	
	# 监听玩家死亡
	Global.hero_died.connect(_on_hero_died)
	
	# 检查是否是 Resume Game 模式
	if Global.is_resuming_quest and Global.quest_progress.has_progress:
		Global.is_resuming_quest = false
		var resume_level = Global.quest_progress.current_level
		start_level(resume_level, true)
	else:
		start_level(0)

func _on_hero_died():
	"""玩家死亡处理"""
	is_level_active = false
	
	# 停止生成怪物
	if spawner:
		spawner.stop_spawning()
	
	# 创建 GameOverScreen 覆盖层
	var game_over_scene = preload("res://Scenes/GameOverScreen.tscn")
	var game_over = game_over_scene.instantiate()
	get_tree().current_scene.add_child(game_over)
	
	var stats = {
		"level_number": current_level + 1,
		"level_name": level_configs[current_level]["name"],
		"monsters_killed": monsters_killed,
		"hero_level": Global.hero_level
	}
	game_over.show_game_over("quest", stats)

# ============================================
# 关卡控制
# ============================================

func start_level(level_index: int, resume_progress: bool = false):
	if level_index >= level_configs.size():
		all_levels_completed.emit()
		return
	
	current_level = level_index
	var config = level_configs[level_index]
	
	# 重置状态
	is_level_cap_reached = false
	is_completing_level = false
	level_experience_gained = 0  # 重置本关经验值
	
	# 如果是恢复进度，使用存档的进度数据
	if resume_progress and Global.quest_progress.has_progress:
		monsters_killed = Global.quest_progress.monsters_killed
		monsters_spawned = Global.quest_progress.monsters_spawned
		level_start_level = Global.quest_progress.level_start_level
	else:
		monsters_killed = 0
		monsters_spawned = 0
		level_start_level = Global.hero_level
		
		Global.quest_progress.level_start_level = level_start_level
	
	is_level_active = true
	
	_update_map_texture(config.get("texture", ""))

	level_started.emit(level_index + 1, config["name"])

	# 通知生成器开始生成
	if spawner:
		if resume_progress and Global.quest_progress.has_progress:
			spawner.start_level(config, monsters_spawned)
		else:
			spawner.start_level(config)

func check_level_complete():
	"""检查是否完成当前关卡
	
	通关条件：
	1. 达到经验上限（停止生成新怪物）
	2. 清除地图上所有现有怪物
	"""
	if not is_level_active or is_completing_level:
		return
	
	# 检查是否还有怪物存活
	var monsters = get_tree().get_nodes_in_group("monsters")
	var alive_monsters = 0
	for monster in monsters:
		if is_instance_valid(monster) and monster.has_method("get_current_health"):
			if monster.get_current_health() > 0:
				alive_monsters += 1
	
	if is_level_cap_reached and alive_monsters <= 0:
		complete_level()

func complete_level():
	"""完成当前关卡"""
	if is_completing_level:
		return
	is_completing_level = true
	is_level_active = false
	level_completed.emit(current_level + 1)
	
	# 保存进度：记录下一关，方便Resume
	_save_next_level_progress()
	
	# 创建 LevelCompleteScreen 覆盖层
	var complete_scene = preload("res://Scenes/LevelCompleteScreen.tscn")
	var complete = complete_scene.instantiate()
	get_tree().current_scene.add_child(complete)
	
	var is_last = (current_level + 1 >= level_configs.size())
	var stats = {
		"monsters_killed": monsters_killed,
		"hero_level": Global.hero_level
	}
	complete.show_level_complete(current_level + 1, level_configs[current_level]["name"], stats, is_last)
	
	if is_last:
		all_levels_completed.emit()

# ============================================
# 怪物管理
# ============================================

func on_monster_killed():
	"""怪物被击杀时调用"""
	if not is_level_active:
		return
	
	monsters_killed += 1
	Global.quest_total_monsters_killed += 1
	_update_monster_count()
	
	check_level_complete()

func on_monster_spawned():
	"""怪物生成时调用"""
	monsters_spawned += 1

func _update_monster_count():
	"""更新怪物计数显示（Quest模式：显示已击杀数）"""
	# Quest模式不再显示剩余怪物数，改为显示已击杀数
	monster_count_changed.emit(monsters_killed, 0)

# ============================================
# 等级上限检查
# ============================================

func _update_map_texture(texture_path: String):
	if texture_path.is_empty():
		return
	var ground = get_tree().get_first_node_in_group("ground")
	if ground and "texture" in ground:
		var tex = load(texture_path)
		if tex:
			ground.texture = tex

func can_gain_experience(amount: int = 0) -> bool:
	"""检查玩家是否还能获得经验
	
	参数:
		amount: 本次要获得的经验值（减半前）
	
	返回 true 表示还能获得经验（未达到上限）
	返回 false 表示已达到上限，不能再获得经验
	"""
	if Global.current_game_mode != Global.GameMode.QUEST:
		return true
	
	if is_level_cap_reached:
		return false
	
	var exp_limit = LEVEL_EXP_REQUIREMENTS[current_level]
	var new_total = level_experience_gained + amount
	var would_exceed = new_total > exp_limit
	
	if would_exceed:
		check_level_limit()
		return false
	
	return true

func get_max_level_this_level() -> int:
	"""获取本关等级上限（基于经验值推算）"""
	# 根据本关经验上限推算最大等级
	# 例如：第1关上限2000，对应升到5级（1→2→3→4→5）
	return level_start_level + 4  # 每关固定升4级

func check_level_limit():
	"""检查是否达到等级上限（基于本关经验值）
	
	达到上限后：
	1. 停止获得经验
	2. 停止生成新怪物
	3. 玩家需要清除地图上剩余的怪物才能通关
	"""
	if Global.current_game_mode != Global.GameMode.QUEST:
		return false
	
	if is_level_cap_reached:
		return true
	
	var exp_limit = LEVEL_EXP_REQUIREMENTS[current_level]
	
	if level_experience_gained >= exp_limit:
		is_level_cap_reached = true
		level_up_limited.emit(get_max_level_this_level())
		
		if spawner:
			if spawner.is_spawning:
				spawner.stop_spawning()
		
		_set_all_monsters_exp_to_zero()
		
		return true
	return false

func _set_all_monsters_exp_to_zero():
	var monsters = get_tree().get_nodes_in_group("monsters")
	var count = 0
	for monster in monsters:
		if monster.has_method("set_experience_reward"):
			monster.set_experience_reward(0)
			count += 1
		elif "experience_reward" in monster:
			monster.experience_reward = 0
			count += 1

# ============================================
# Quest 进度存档管理
# ============================================

func _save_next_level_progress():
	"""保存下一关进度（通关后调用）
	
	Resume时从下一关开头开始，保留玩家等级和属性
	同时更新关卡解锁进度
	"""
	var next_level = current_level + 1
	if next_level >= level_configs.size():
		# 全部完成，清除进度
		_clear_quest_progress()
		return
	
	# 保存下一关进度
	Global.quest_progress.current_level = next_level
	Global.quest_progress.monsters_killed = 0  # 从开头开始
	Global.quest_progress.monsters_spawned = 0
	Global.quest_progress.level_start_level = Global.hero_level  # 保留当前等级
	Global.quest_progress.has_progress = true
	
	# 更新关卡解锁进度（解锁下一关）
	if next_level > Global.quest_max_unlocked_level:
		Global.quest_max_unlocked_level = next_level
	
	_save_to_auto_slot()

func _clear_quest_progress():
	"""清除Quest进度（全部完成后调用）"""
	Global.quest_progress.current_level = 0
	Global.quest_progress.monsters_killed = 0
	Global.quest_progress.monsters_spawned = 0
	Global.quest_progress.level_start_level = 1
	Global.quest_progress.has_progress = false
	
	# 清除自动存档
	_save_to_auto_slot()

func _save_to_auto_slot():
	"""保存到自动存档槽位"""
	# 使用hero的位置
	var hero = get_tree().get_first_node_in_group("hero")
	if hero:
		Global.hero_save_position = hero.global_position
	
	# 调用SaveManager保存到槽位2
	var result = SaveManager.save_game(2)
