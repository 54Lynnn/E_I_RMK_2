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
# 每关包含：关卡名称、总怪物数、波次配置、允许出现的怪物类型
var level_configs := [
	{ "name": "Ancient Way",       "total_monsters": 20,  "waves": [4, 4, 4, 4, 4],         "allowed_monsters": ["spider", "troll"] },
	{ "name": "Burned Land",       "total_monsters": 30,  "waves": [6, 6, 6, 6, 6],         "allowed_monsters": ["spider", "troll", "bear"] },
	{ "name": "Desert Battle",     "total_monsters": 40,  "waves": [6, 6, 6, 6, 6, 6, 4],   "allowed_monsters": ["spider", "bear", "mummy"] },
	{ "name": "Forgotten Dunes",   "total_monsters": 50,  "waves": [6, 6, 6, 6, 6, 6, 6, 6, 2], "allowed_monsters": ["bear", "mummy", "demon"] },
	{ "name": "Dark Swamp",        "total_monsters": 60,  "waves": [9, 9, 9, 9, 9, 9, 6],   "allowed_monsters": ["mummy", "demon", "reaper"] },
	{ "name": "Skull Coast",       "total_monsters": 70,  "waves": [9, 9, 9, 9, 9, 9, 9, 7], "allowed_monsters": ["demon", "reaper", "troll"] },
	{ "name": "Snowy Pass",        "total_monsters": 80,  "waves": [9, 9, 9, 9, 9, 9, 9, 9, 9, 7], "allowed_monsters": ["reaper", "troll", "diablo"] },
	{ "name": "Hell Eye",          "total_monsters": 90,  "waves": [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9], "allowed_monsters": ["troll", "diablo"] },
	{ "name": "Inferno",           "total_monsters": 100, "waves": [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 4], "allowed_monsters": ["demon", "reaper", "troll", "diablo"] },
	{ "name": "Diablo's Lair",     "total_monsters": 120, "waves": [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9], "allowed_monsters": ["diablo", "troll", "reaper"] }
]

# 当前状态
var current_level := 0          # 当前关卡索引（0-9）
var monsters_killed := 0        # 本关已击杀怪物数
var monsters_spawned := 0       # 本关已生成怪物数
var total_monsters_in_level := 0 # 本关总怪物数
var is_level_active := false    # 当前是否在进行中
var level_start_level := 1      # 进入本关时的玩家等级

# 等级上限系统
const LEVELS_PER_QUEST := 4     # 每关最多升4级

# 引用
@onready var spawner := $QuestMonsterSpawner

func _ready():
	# 等待场景准备好
	await get_tree().process_frame
	
	# 监听玩家死亡
	Global.hero_died.connect(_on_hero_died)
	
	start_level(0)

func _on_hero_died():
	"""玩家死亡处理"""
	is_level_active = false
	print("Quest: 玩家死亡，游戏结束！")
	
	# 停止生成怪物
	if spawner:
		spawner.stop_spawning()
	
	# 显示游戏结束（可以在这里添加UI提示）
	# 延迟后返回主菜单
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

# ============================================
# 关卡控制
# ============================================

func start_level(level_index: int):
	"""开始指定关卡"""
	if level_index >= level_configs.size():
		all_levels_completed.emit()
		return
	
	current_level = level_index
	var config = level_configs[level_index]
	total_monsters_in_level = config["total_monsters"]
	monsters_killed = 0
	monsters_spawned = 0
	is_level_active = true
	level_start_level = Global.hero_level
	
	print("Quest: 开始关卡 %d - %s" % [level_index + 1, config["name"]])
	print("Quest: 需要击杀 %d 只怪物" % total_monsters_in_level)
	
	level_started.emit(level_index + 1, config["name"])
	monster_count_changed.emit(total_monsters_in_level, total_monsters_in_level)
	
	# 通知生成器开始生成
	if spawner:
		spawner.start_level(config)

func check_level_complete():
	"""检查是否完成当前关卡"""
	if not is_level_active:
		return
	
	# 条件：所有怪物都被击杀，且没有待生成的怪物
	var remaining = total_monsters_in_level - monsters_killed
	if remaining <= 0 and spawner and spawner.all_waves_spawned:
		complete_level()

func complete_level():
	"""完成当前关卡"""
	is_level_active = false
	print("Quest: 关卡 %d 完成！" % (current_level + 1))
	level_completed.emit(current_level + 1)
	
	# 延迟后进入下一关
	await get_tree().create_timer(2.0).timeout
	
	# 检查是否还有下一关
	if current_level + 1 >= level_configs.size():
		# 全部完成
		all_levels_completed.emit()
		print("Quest: 恭喜！所有关卡已完成！")
		await get_tree().create_timer(5.0).timeout
		get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")
	else:
		start_level(current_level + 1)

# ============================================
# 怪物管理
# ============================================

func on_monster_killed():
	"""怪物被击杀时调用"""
	if not is_level_active:
		return
	
	monsters_killed += 1
	var remaining = total_monsters_in_level - monsters_killed
	monster_count_changed.emit(remaining, total_monsters_in_level)
	
	print("Quest: 击杀 %d/%d" % [monsters_killed, total_monsters_in_level])
	
	# 检查通关
	check_level_complete()

func on_monster_spawned():
	"""怪物生成时调用"""
	monsters_spawned += 1

# ============================================
# 等级上限检查
# ============================================

func can_gain_experience() -> bool:
	"""检查玩家是否还能获得经验"""
	if Global.current_game_mode != Global.GameMode.QUEST:
		return true
	
	var levels_gained = Global.hero_level - level_start_level
	return levels_gained < LEVELS_PER_QUEST

func get_max_level_this_level() -> int:
	"""获取本关等级上限"""
	return level_start_level + LEVELS_PER_QUEST

func check_level_limit():
	"""检查是否达到等级上限"""
	if Global.current_game_mode != Global.GameMode.QUEST:
		return
	
	var levels_gained = Global.hero_level - level_start_level
	if levels_gained >= LEVELS_PER_QUEST:
		level_up_limited.emit(get_max_level_this_level())
		return true
	return false
