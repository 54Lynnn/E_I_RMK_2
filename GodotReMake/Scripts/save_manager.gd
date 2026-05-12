extends Node

# ============================================
# SaveManager.gd - 存档管理器
# ============================================
# 使用 FileAccess + JSON 实现存档系统
# 存档位置: user://saves/save_X.json
#
# 使用方法:
#   SaveManager.save_game(1)  # 保存到槽位1
#   SaveManager.load_game(1)  # 从槽位1读取
# ============================================

const SAVE_DIR := "user://saves"
const SAVE_PREFIX := "save_"
const SAVE_EXT := ".json"
const CURRENT_VERSION := "1.0"  # 存档格式版本，用于兼容性检查

# 信号
signal game_saved(slot: int)     # 存档成功时发射
signal game_loaded(slot: int)    # 读档成功时发射
signal save_error(msg: String)   # 存档失败时发射
signal load_error(msg: String)   # 读档失败时发射

# ============================================
# 获取存档路径
# ============================================
static func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "/" + SAVE_PREFIX + str(slot) + SAVE_EXT

# ============================================
# 确保存档目录存在
# ============================================
static func _ensure_save_dir() -> bool:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var err = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			push_error("SaveManager: 无法创建存档目录: " + SAVE_DIR)
			return false
	return true

# ============================================
# 保存游戏
# ============================================
static func save_game(slot: int) -> bool:
	if slot < 1 or slot > 9:
		push_error("SaveManager: 存档槽位必须在1-9之间")
		return false
	
	if not _ensure_save_dir():
		return false
	
	# 构建存档数据
	var save_data := _build_save_data()
	
	# 转换为JSON
	var json_text := JSON.stringify(save_data, "\t", false, true)
	
	# 写入文件
	var path := _get_save_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: 无法打开文件进行写入: " + path + ", 错误码: " + str(FileAccess.get_open_error()))
		return false
	
	file.store_string(json_text)
	file.close()
	
	print("SaveManager: 游戏已保存到槽位 ", slot)
	return true

# ============================================
# 构建存档数据字典
# ============================================
static func _build_save_data() -> Dictionary:
	var hero_pos := Global.hero_save_position if "hero_save_position" in Global else Vector2(1280, 1280)
	var data := {
		"version": CURRENT_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game": {
			"difficulty": Global.current_difficulty,
			"game_mode": Global.current_game_mode,
		},
		"hero": {
			"level": Global.hero_level,
			"experience": Global.hero_experience,
			"health": Global.health,
			"mana": Global.mana,
			"position_x": hero_pos.x,
			"position_y": hero_pos.y,
		},
		"attributes": {
			"strength": Global.hero_strength,
			"dexterity": Global.hero_dexterity,
			"stamina": Global.hero_stamina,
			"intelligence": Global.hero_intelligence,
			"wisdom": Global.hero_wisdom,
			"attribute_points": Global.attribute_points,
			"skill_points": Global.skill_points,
		},
		"skills": Global.skill_levels.duplicate(),
		"buffs": {
			"damage_multiplier": Global.damage_multiplier,
			"speed_multiplier": Global.speed_multiplier,
			"physic_resist": Global.physic_resist,
			"magic_resist": Global.magic_resist,
			"free_spells": Global.free_spells,
			"invulnerable": Global.invulnerable,
		},
		"quest_progress": Global.quest_progress.duplicate(),
		"quest_max_unlocked_level": Global.quest_max_unlocked_level,
		"quick_slots": {
			"lmb": Global.quick_slot_lmb,
			"rmb": Global.quick_slot_rmb,
			"shift": Global.quick_slot_shift,
			"space": Global.quick_slot_space,
		},
	}
	return data

# ============================================
# 读取游戏
# ============================================
static func load_game(slot: int) -> bool:
	if slot < 1 or slot > 9:
		push_error("SaveManager: 存档槽位必须在1-9之间")
		return false
	
	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: 存档不存在: " + path)
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: 无法打开存档文件: " + path)
		return false
	
	var json_text := file.get_as_text()
	file.close()
	
	# 解析JSON
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("SaveManager: JSON解析失败: " + json.get_error_message() + " 在行 " + str(json.get_error_line()))
		return false
	
	var save_data: Dictionary = json.data
	
	# 版本检查
	var version: String = save_data.get("version", "0.0")
	if version != CURRENT_VERSION:
		push_warning("SaveManager: 存档版本不匹配 (存档:" + version + ", 当前:" + CURRENT_VERSION + ")，尝试兼容加载")
	
	# 应用存档数据
	_apply_save_data(save_data)
	
	print("SaveManager: 游戏已从槽位 ", slot, " 加载")
	return true

# ============================================
# 清理当前游戏状态（读档前调用）
# ============================================
static func _clear_game_state():
	var tree = Engine.get_main_loop()
	if not tree:
		return
	
	# 1. 移除所有怪物
	var monsters = tree.get_nodes_in_group("monsters")
	for m in monsters:
		if is_instance_valid(m):
			m.queue_free()
	
	# 2. 重置刷怪计数器
	var spawners = tree.get_nodes_in_group("monster_spawners")
	for s in spawners:
		if is_instance_valid(s) and s.has_method("reset_spawner"):
			s.reset_spawner()
	
	# 3. 清理掉落物
	var pickups = tree.get_nodes_in_group("pickup_items")
	for p in pickups:
		if is_instance_valid(p):
			p.queue_free()
	
	# 4. 重置英雄冷却（通过 Global 信号通知 hero）
	Global.load_game_started.emit()

# ============================================
# 应用存档数据到游戏
# ============================================
static func _apply_save_data(data: Dictionary):
	# 清理当前游戏状态（怪物、投射物等）
	_clear_game_state()
	
	# 游戏设置
	if data.has("game"):
		var game_data: Dictionary = data.game
		if game_data.has("difficulty"):
			Global.current_difficulty = game_data.difficulty
		if game_data.has("game_mode"):
			Global.current_game_mode = game_data.game_mode
	
	# 英雄基础状态
	if data.has("hero"):
		var hero_data: Dictionary = data.hero
		if hero_data.has("level"):
			Global.hero_level = hero_data.level
		if hero_data.has("experience"):
			Global.hero_experience = hero_data.experience
		if hero_data.has("health"):
			Global.health = hero_data.health
		if hero_data.has("mana"):
			Global.mana = hero_data.mana
		if hero_data.has("position_x") and hero_data.has("position_y"):
			Global.hero_save_position = Vector2(hero_data.position_x, hero_data.position_y)
	
	# 属性
	if data.has("attributes"):
		var attr_data: Dictionary = data.attributes
		if attr_data.has("strength"):
			Global.hero_strength = attr_data.strength
		if attr_data.has("dexterity"):
			Global.hero_dexterity = attr_data.dexterity
		if attr_data.has("stamina"):
			Global.hero_stamina = attr_data.stamina
		if attr_data.has("intelligence"):
			Global.hero_intelligence = attr_data.intelligence
		if attr_data.has("wisdom"):
			Global.hero_wisdom = attr_data.wisdom
		if attr_data.has("attribute_points"):
			Global.attribute_points = attr_data.attribute_points
		if attr_data.has("skill_points"):
			Global.skill_points = attr_data.skill_points
	
	# 技能等级
	if data.has("skills"):
		var skills_data: Dictionary = data.skills
		for skill_id in skills_data.keys():
			if Global.skill_levels.has(skill_id):
				Global.skill_levels[skill_id] = skills_data[skill_id]
	
	# Buff/倍率状态恢复
	if data.has("buffs"):
		var buffs_data: Dictionary = data.buffs
		if buffs_data.has("damage_multiplier"):
			Global.damage_multiplier = buffs_data.damage_multiplier
		if buffs_data.has("speed_multiplier"):
			Global.speed_multiplier = buffs_data.speed_multiplier
		if buffs_data.has("physic_resist"):
			Global.physic_resist = buffs_data.physic_resist
		if buffs_data.has("magic_resist"):
			Global.magic_resist = buffs_data.magic_resist
		if buffs_data.has("free_spells"):
			Global.free_spells = buffs_data.free_spells
		if buffs_data.has("invulnerable"):
			Global.invulnerable = buffs_data.invulnerable
	
	# Quest 进度恢复
	if data.has("quest_progress"):
		var qp: Dictionary = data.quest_progress
		Global.quest_progress.current_level = qp.get("current_level", 0)
		Global.quest_progress.monsters_killed = qp.get("monsters_killed", 0)
		Global.quest_progress.monsters_spawned = qp.get("monsters_spawned", 0)
		Global.quest_progress.level_start_level = qp.get("level_start_level", 1)
		Global.quest_progress.has_progress = qp.get("has_progress", false)
	
	# 关卡解锁进度恢复
	if data.has("quest_max_unlocked_level"):
		Global.quest_max_unlocked_level = data.quest_max_unlocked_level
	
	# 快捷槽位恢复
	if data.has("quick_slots"):
		Global.quick_slot_lmb = data.quick_slots.get("lmb", "")
		Global.quick_slot_rmb = data.quick_slots.get("rmb", "")
		Global.quick_slot_shift = data.quick_slots.get("shift", "")
		Global.quick_slot_space = data.quick_slots.get("space", "")
	
	# 重新计算衍生属性
	Global.apply_strength()
	Global.apply_dexterity()
	Global.apply_intelligence()
	
	# 确保生命和法力不超过最大值
	Global.health = min(Global.health, Global.max_health)
	Global.mana = min(Global.mana, Global.max_mana)
	
	# 重新应用被动技能
	var Fortuna = preload("res://Scripts/Spells/fortuna.gd")
	Fortuna.update_drop_rate()
	
	# 发射信号通知UI更新
	Global.experience_changed.emit(Global.hero_experience, Global.hero_level * 200)
	Global.level_changed.emit(Global.hero_level)
	Global.health_changed.emit(Global.health, Global.max_health)
	Global.mana_changed.emit(Global.mana, Global.max_mana)

# ============================================
# 检查存档是否存在
# ============================================
static func has_save(slot: int) -> bool:
	if slot < 1 or slot > 9:
		return false
	var path := _get_save_path(slot)
	return FileAccess.file_exists(path)

# ============================================
# 删除存档
# ============================================
static func delete_save(slot: int) -> bool:
	if slot < 1 or slot > 9:
		return false
	var path := _get_save_path(slot)
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		if err == OK:
			print("SaveManager: 存档槽位 ", slot, " 已删除")
			return true
		else:
			push_error("SaveManager: 删除存档失败: " + path)
			return false
	return false

# ============================================
# 获取存档信息（用于存档列表显示）
# ============================================
static func get_save_info(slot: int) -> Dictionary:
	var info := {
		"exists": false,
		"slot": slot,
		"timestamp": 0,
		"level": 0,
		"game_mode": 0,
		"difficulty": 0,
		"quest_level": 0,
		"has_quest_progress": false,
	}
	
	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return info
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return info
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		return info
	
	var save_data: Dictionary = json.data
	info.exists = true
	info.timestamp = save_data.get("timestamp", 0)
	
	if save_data.has("hero"):
		var hero_data: Dictionary = save_data.hero
		info.level = hero_data.get("level", 0)
	
	if save_data.has("game"):
		var game_data: Dictionary = save_data.game
		info.game_mode = game_data.get("game_mode", 0)
		info.difficulty = game_data.get("difficulty", 0)
	
	# Quest 进度信息
	if save_data.has("quest_progress"):
		var qp: Dictionary = save_data.quest_progress
		info.quest_level = qp.get("current_level", 0)
		info.has_quest_progress = qp.get("has_progress", false)
	else:
		info.quest_level = 0
		info.has_quest_progress = false
	
	return info

# ============================================
# 获取所有存档信息
# ============================================
static func get_all_save_info() -> Array:
	var saves := []
	for i in range(1, 10):
		saves.append(get_save_info(i))
	return saves
