extends Node

# ============================================
# MonsterDatabase.gd - 怪物数据库
# ============================================
# 集中管理所有怪物的数值配置。
# 数据来源于原版游戏 Manual 和 Data.pak 解密文件。
#
# 使用方式：
#   var data = MonsterDatabase.get_monster_data("spider", player_level, difficulty)
#   health = data.health
# ============================================

# 怪物类型枚举
enum MonsterType {
	TROLL,      # Troll (Rig) - 弱近战
	SPIDER,     # Spider - 坚韧但笨重的昆虫
	MUMMY,      # Mummy - 快速远程战士
	DEMON,      # Blood Demon - 优秀的近战战士，追击时加速40%
	BEAR,       # Bear - 强近战战士
	REAPER,     # Reaper - 强战士，魔法远程攻击，3个火焰
	DIABLO      # Diablo - 不直接战斗，召唤其他怪物
}

# 难度枚举
enum Difficulty {
	NORMAL,     # 普通：怪物血量-40%，速度-40%
	NIGHTMARE,  # 噩梦：怪物血量-20%，速度-20%
	HARDCORE    # 硬核：100%属性（Survival模式默认）
}

# ============================================
# 原版游戏怪物数据（来自 Manual.htm）
# ============================================
# 格式说明：
# - experience: 击杀获得经验值
# - attack_rate: 攻击间隔（秒）
# - health_per_level: 每级生命值增长
# - attack_range_min/max: 攻击距离范围
# - speed_base: 基础速度
# - speed_per_level: 每级速度增长
# - damage_base: 基础伤害
# - damage_per_level: 每级伤害增长
#
# 原版游戏机制：
# - 怪物等级 = 英雄等级（新刷新的怪物）
# - 生命值 = health_per_level × level
# - 速度 = speed_base + speed_per_level × (level - 1)
# - 伤害 = damage_base + damage_per_level × (level - 1)
#
# 难度修正：
# - Normal: 血量×0.6, 速度×0.6
# - Nightmare: 血量×0.8, 速度×0.8
# - Hardcore: 血量×1.0, 速度×1.0
#
# Survival模式40级后额外加成：
# - 每级额外+10%血量和+10%速度
# - 例如60级：+200%血量和速度
# ============================================

const MONSTER_DATA := {
	"troll": {
		"name": "Troll",
		"type": MonsterType.TROLL,
		"experience": 30,
		"attack_rate": 2.0,
		"health_per_level": 7.0,
		"attack_range_min": 0.0,
		"attack_range_max": 40.0,
		"speed_base": 60.0,
		"speed_per_level": 0.85,
		"damage_base": 5.0,
		"damage_per_level": 1.0,
		"collision_damage": 2.0,
		"detection_range": 350.0,
		"min_distance": 40.0,
		"rotation_speed": 0.5,
		"description": "Weak melee fighter."
	},
	"spider": {
		"name": "Spider",
		"type": MonsterType.SPIDER,
		"experience": 40,
		"attack_rate": 2.0,
		"health_per_level": 10.0,
		"attack_range_min": 0.0,
		"attack_range_max": 40.0,
		"speed_base": 60.0,
		"speed_per_level": 0.9,
		"damage_base": 6.0,
		"damage_per_level": 1.5,
		"collision_damage": 2.0,
		"detection_range": 350.0,
		"min_distance": 40.0,
		"rotation_speed": 0.75,
		"description": "Tough though stupid insect."
	},
	"mummy": {
		"name": "Mummy",
		"type": MonsterType.MUMMY,
		"experience": 50,
		"attack_rate": 4.0,
		"health_per_level": 4.0,
		"attack_range_min": 150.0,
		"attack_range_max": 300.0,
		"speed_base": 65.0,
		"speed_per_level": 0.95,
		"damage_base": 4.0,
		"damage_per_level": 1.25,
		"collision_damage": 0.0,
		"detection_range": 500.0,
		"min_distance": 150.0,
		"rotation_speed": 1.5,
		"description": "Fast warrior with range attack."
	},
	"demon": {
		"name": "Blood Demon",
		"type": MonsterType.DEMON,
		"experience": 60,
		"attack_rate": 2.0,
		"health_per_level": 8.0,
		"attack_range_min": 0.0,
		"attack_range_max": 40.0,
		"speed_base": 60.0,
		"speed_per_level": 0.95,
		"damage_base": 8.0,
		"damage_per_level": 2.0,
		"collision_damage": 3.0,
		"detection_range": 400.0,
		"min_distance": 40.0,
		"rotation_speed": 0.4,
		"description": "Exceptional melee fighter. When demon starts to pursuit its speed increases by 40%."
	},
	"bear": {
		"name": "Bear",
		"type": MonsterType.BEAR,
		"experience": 70,
		"attack_rate": 2.0,
		"health_per_level": 9.0,
		"attack_range_min": 0.0,
		"attack_range_max": 40.0,
		"speed_base": 65.0,
		"speed_per_level": 0.9,
		"damage_base": 10.0,
		"damage_per_level": 2.5,
		"collision_damage": 5.0,
		"detection_range": 350.0,
		"min_distance": 40.0,
		"rotation_speed": 0.6,
		"description": "Strong melee fighter."
	},
	"reaper": {
		"name": "Reaper",
		"type": MonsterType.REAPER,
		"experience": 80,
		"attack_rate": 8.0,
		"health_per_level": 10.0,
		"attack_range_min": 150.0,
		"attack_range_max": 300.0,
		"speed_base": 60.0,
		"speed_per_level": 0.9,
		"damage_base": 4.0,
		"damage_per_level": 1.5,
		"collision_damage": 2.0,
		"detection_range": 500.0,
		"min_distance": 150.0,
		"rotation_speed": 1.5,
		"description": "Strong warrior with magic range attack. Attacks with 3 flames."
	},
	"diablo": {
		"name": "Diablo",
		"type": MonsterType.DIABLO,
		"experience": 200,
		"attack_rate": 15.0,
		"health_per_level": 25.0,
		"attack_range_min": 150.0,
		"attack_range_max": 380.0,
		"speed_base": 55.0,
		"speed_per_level": 0.85,
		"damage_base": 0.0,
		"damage_per_level": 0.0,
		"collision_damage": 8.0,
		"detection_range": 500.0,
		"min_distance": 150.0,
		"rotation_speed": 1.5,
		"description": "Does not fight with the hero himself. Summons different monsters around the hero."
	}
}

# ============================================
# 难度修正系数
# ============================================
const DIFFICULTY_MODIFIERS := {
	Difficulty.NORMAL: {
		"health_mult": 0.6,
		"speed_mult": 0.6
	},
	Difficulty.NIGHTMARE: {
		"health_mult": 0.8,
		"speed_mult": 0.8
	},
	Difficulty.HARDCORE: {
		"health_mult": 1.0,
		"speed_mult": 1.0
	}
}

# ============================================
# 获取怪物数据（支持等级缩放和难度修正）
# ============================================
# 参数:
#   monster_id: 怪物ID
#   monster_level: 怪物等级（通常为英雄等级）
#   difficulty: 难度（Normal/Nightmare/Hardcore）
#   is_survival: 是否为Survival模式（影响40级后加成）
# 返回:
#   包含计算后属性的字典
# ============================================
static func get_monster_data(
	monster_id: String, 
	monster_level: int = 1,
	difficulty: int = Difficulty.NORMAL,
	is_survival: bool = false
) -> Dictionary:
	if not MONSTER_DATA.has(monster_id):
		push_error("MonsterDatabase: 未知的怪物ID: " + monster_id)
		return {}
	
	var base_data = MONSTER_DATA[monster_id].duplicate(true)
	var level = max(1, monster_level)
	
	# 获取难度修正
	var diff_mod = DIFFICULTY_MODIFIERS[difficulty]
	
	# 计算基础属性（原版公式）
	# 生命 = 基础值 + 每级成长 × 等级
	# 速度 = 基础值 + 每级成长 × 等级
	# 伤害 = 基础值 + 每级成长 × 等级
	var health = base_data.health_per_level * level
	var speed = base_data.speed_base + base_data.speed_per_level * level
	var damage = base_data.damage_base + base_data.damage_per_level * level
	
	# 应用难度修正
	health *= diff_mod.health_mult
	speed *= diff_mod.speed_mult
	
	# Survival模式40级后额外加成
	if is_survival and level > 40:
		var bonus_levels = level - 40
		var bonus_percent = bonus_levels * 0.1  # 每级+10%
		health *= (1.0 + bonus_percent)
		speed *= (1.0 + bonus_percent)
	
	# 组装最终数据
	var result = base_data.duplicate(true)
	result.health = health
	result.max_health = health
	result.move_speed = speed
	result.damage = damage
	result.attack_range = base_data.attack_range_max
	result.attack_cooldown = base_data.attack_rate
	
	# 经验值计算（Quest模式减半）
	var exp_mult = 0.5 if not is_survival else 1.0
	result.experience_reward = int(base_data.experience * exp_mult)
	
	# 恶魔特殊机制：追击时速度+40%
	if monster_id == "demon":
		result.pursuit_speed_bonus = 1.4
	
	return result

# ============================================
# 获取怪物基础数据（不应用等级缩放）
# ============================================
static func get_monster_base_data(monster_id: String) -> Dictionary:
	if MONSTER_DATA.has(monster_id):
		return MONSTER_DATA[monster_id].duplicate(true)
	push_error("MonsterDatabase: 未知的怪物ID: " + monster_id)
	return {}

# ============================================
# 获取怪物列表
# ============================================
static func get_all_monster_ids() -> Array:
	return MONSTER_DATA.keys()

static func get_normal_monster_ids() -> Array:
	# 返回普通怪物（非Diablo）
	var ids = []
	for id in MONSTER_DATA.keys():
		if id != "diablo":
			ids.append(id)
	return ids

# ============================================
# Diablo召唤概率表
# ============================================
static func get_diablo_summon_table() -> Dictionary:
	return {
		"reaper": 0.05,    # 5%
		"demon": 0.10,     # 10%
		"bear": 0.15,      # 15%
		"mummy": 0.20,     # 20%
		"spider": 0.25,    # 25%
		"troll": 0.25      # 25%
	}

# ============================================
# 根据关卡获取适合的怪物
# ============================================
static func get_monsters_for_level(level: int) -> Array:
	var level_requirements := {
		"troll": 1,
		"mummy": 3,
		"spider": 6,
		"demon": 14,
		"bear": 18,
		"reaper": 26,
		"diablo": 35,
	}
	
	var suitable = []
	for id in MONSTER_DATA.keys():
		var min_level = level_requirements.get(id, 99)
		if level >= min_level:
			suitable.append(id)
	
	return suitable

# ============================================
# 怪物出现权重（越高出现越频繁）
# ============================================
const MONSTER_WEIGHTS := {
	"troll": 25,
	"mummy": 22,
	"spider": 18,
	"demon": 15,
	"bear": 10,
	"reaper": 5,
	"diablo": 2,
}

# ============================================
# 按权重随机选择一种怪物（可排除指定种类）
# ============================================
static func pick_monster_for_level(level: int, exclude: Array = []) -> String:
	var suitable = get_monsters_for_level(level)
	if suitable.is_empty():
		return "troll"
	
	# 移除被排除的怪物
	if not exclude.is_empty():
		var filtered = []
		for id in suitable:
			if not id in exclude:
				filtered.append(id)
		if filtered.is_empty():
			filtered = suitable  # 全被排除则用原列表
		suitable = filtered
	
	# 计算可用怪物的总权重
	var total_weight := 0
	for id in suitable:
		total_weight += MONSTER_WEIGHTS.get(id, 10)
	
	# 按权重随机选择
	var roll = randi() % total_weight
	var cumulative := 0
	for id in suitable:
		cumulative += MONSTER_WEIGHTS.get(id, 10)
		if roll < cumulative:
			return id
	
	return suitable[-1]

# ============================================
# 计算怪物威胁值（用于平衡）
# ============================================
static func get_threat_level(
	monster_id: String, 
	monster_level: int = 1,
	difficulty: int = Difficulty.NORMAL
) -> float:
	var data = get_monster_data(monster_id, monster_level, difficulty)
	if data.is_empty():
		return 0.0
	# 威胁值 = 血量 × 伤害 × (速度/50)
	return data.health * data.damage * (data.move_speed / 50.0)

# ============================================
# 获取怪物等级缩放预览
# ============================================
static func get_level_scaling_preview(
	monster_id: String, 
	max_level: int = 10,
	difficulty: int = Difficulty.NORMAL,
	is_survival: bool = false
) -> Array:
	var previews = []
	for level in range(1, max_level + 1):
		var data = get_monster_data(monster_id, level, difficulty, is_survival)
		previews.append({
			"level": level,
			"health": data.health,
			"damage": data.damage,
			"speed": data.move_speed,
			"exp": data.experience_reward
		})
	return previews

# ============================================
# 获取难度名称
# ============================================
static func get_difficulty_name(difficulty: int) -> String:
	match difficulty:
		Difficulty.NORMAL:
			return "Normal"
		Difficulty.NIGHTMARE:
			return "Nightmare"
		Difficulty.HARDCORE:
			return "Hardcore"
		_:
			return "Unknown"
