extends Node

# ============================================
# Global.gd - 全局单例脚本 (AutoLoad)
# ============================================
# 这个文件是游戏的核心数据中心，存储所有全局状态。
# 它在游戏启动时自动加载，任何脚本都可以通过 Global.xxx 访问这里的数据。
# 
# 主要功能：
# 1. 玩家属性（生命值、法力值、等级、经验）
# 2. 技能系统（21个技能的等级管理）
# 3. 属性点系统（力量、敏捷等）
# 4. 各种buff/状态管理
# 5. 信号系统（通知UI更新）
# ============================================

const Fortuna = preload("res://Scripts/Spells/fortuna.gd")

# 开发者模式开关 - 开启后按T键可获得大量属性点和技能点
var dev_mode := false

# ============================================
# 游戏难度设置
# ============================================
# 难度影响怪物属性：
# - Normal: 怪物血量×0.6, 速度×0.6
# - Nightmare: 怪物血量×0.8, 速度×0.8  
# - Hardcore: 怪物血量×1.0, 速度×1.0
#
# 游戏模式：
# - Quest: 经验值减半
# - Survival: 40级后怪物每级额外+10%血量和速度
# ============================================
enum Difficulty { NORMAL, NIGHTMARE, HARDCORE }
enum GameMode { QUEST, SURVIVAL }

var current_difficulty := Difficulty.NORMAL
var current_game_mode := GameMode.SURVIVAL

# ============================================
# 枚举定义 - 用于类型标识
# ============================================

# 怪物类型枚举 - 标识不同种类的敌人
enum MonsterType { ARCHER, BEAR, BOSS, DEMON, REAPER, RIG, SPIDER, HERO }

# 法术类型枚举 - 标识不同的技能/法术
enum SpellType {
	FIRE_BALL,        # 火球术
	LIGHTNING,        # 闪电术（右键基础技能）
	FREEZING_SPEAR,   # 冰冻矛
	MAGIC_MISSILE,    # 魔法飞弹（默认技能）
	HOLY_LIGHT,       # 圣光
	HEAL,             # 治疗
	POISON_CLOUD,     # 毒云
	NOVA,             # 新星
	METEOR,           # 陨石
	BALL_LIGHTNING,   # 球状闪电
	TELEPORT,         # 传送
	PRAYER,           # 祈祷
	SACRIFICE,        # 牺牲
	DARK_RITUAL,      # 黑暗仪式
	WRATH_OF_GOD,     # 神之愤怒
	ARMAGEDDON,       # 末日审判
	SLOW,             # 减速
	FIRE_WALK,        # 火焰行走
	FORTUNE,          # 幸运
	STONE_ENCHANTED,  # 石化附魔
	TELEKINESIS       # 心灵感应
}

# 物品类型枚举 - 标识掉落物品的种类
enum ItemType {
	HEALTH_POTION,      # 生命药水
	MANA_POTION,        # 法力药水
	REJUVENATION,       # 恢复药水
	QUAD_DAMAGE,        # 四倍伤害
	PHYSIC_SHIELD,      # 物理护盾
	MAGIC_SHIELD,       # 魔法护盾
	SPEED_BOOTS,        # 速度之靴
	INVULNERABILITY,    # 无敌
	FREE_SPELLS,        # 免费施法
	TOME_OF_EXPERIENCE, # 经验之书
	ATTRIBUTE_POINT,    # 属性点
	SKILL_POINT         # 技能点
}

# ============================================
# 信号定义 - 用于通知其他系统状态变化
# ============================================
# 使用方式：Global.experience_changed.connect(某个函数)
# 当经验值变化时，所有连接的函数都会被调用

signal experience_changed(exp, exp_to_next)    # 经验值变化时发射
signal level_changed(level)                     # 等级变化时发射
signal health_changed(health, max_health)       # 生命值变化时发射
signal mana_changed(mana, max_mana)             # 法力值变化时发射
signal hero_died                                # 英雄死亡时发射
signal skill_level_changed(skill_id, level)     # 技能等级变化时发射
signal hero_took_damage(amount, is_magic, attacker)  # 英雄受到伤害时发射（用于被动技能）
signal load_game_started                        # 读档开始时发射（用于清理英雄状态）

# PauseMenu 是否打开（用于 HeroPanel 互斥）
var is_pause_menu_open := false
# HeroPanel 是否打开（用于 PauseMenu 互斥）
var hero_panel_is_open := false

# ============================================
# 基础属性 - 玩家等级和经验
# ============================================

var hero_level := 1        # 当前等级，初始为1
var hero_experience := 0   # 当前经验值，升级需要 hero_level * 200 点经验（简化公式）

# ============================================
# 属性点系统 - 五大基础属性
# ============================================
# 每次升级获得5点属性点，可在英雄面板分配
# 属性上限：100点
# 技能上限：10级
#
# 原版数据（来自 Manual 和 HeroBalance.txt）：
# Strength:
#   - 1点 = +10生命值
#   - 1点 = -0.004秒受击恢复时间（基础0.5秒）
# Dexterity:
#   - 1点 = +0.5移动速度（基础65）
#   - 1点 = -0.4%被命中率（基础100%）
# Stamina:
#   - 1点 = +0.1生命恢复/秒
#   - 1点 = +0.35移动速度
# Intelligence:
#   - 1点 = +6法力值
#   - 1点 = +0.06法力恢复/秒
# Wisdom:
#   - 1点 = +2法力值
#   - 1点 = +0.18法力恢复/秒
# ============================================

var hero_strength := 10       # 力量：影响最大生命值和受击恢复（原版初始10点）
var hero_dexterity := 10      # 敏捷：影响移动速度和被命中几率（原版初始10点）
var hero_stamina := 10        # 耐力：影响生命恢复和移动速度（原版初始10点）
var hero_intelligence := 10   # 智力：影响最大法力值和法力恢复（原版初始10点）
var hero_wisdom := 10         # 智慧：影响法力值和法力恢复（原版初始10点）

var attribute_points := 0     # 当前可用的属性点数
var skill_points := 0         # 当前可用的技能点数

# 属性上限
const MAX_ATTRIBUTE := 100
const MAX_SKILL_LEVEL := 10

# ============================================
# 技能等级系统 - 21个技能的等级管理
# ============================================
# 技能等级范围：0-10
# 0级 = 未学习（灰色，不可用）
# 1-10级 = 已学习（彩色，可用）
# 
# 修改技能等级的方式：
# Global.skill_levels["magic_missile"] = 1  # 设置魔法飞弹为1级
# Global.skill_level_changed.emit("magic_missile", 1)  # 通知UI更新

var skill_levels := {
	"magic_missile": 1,       # 魔法飞弹
	"prayer": 1,              # 祈祷
	"teleport": 1,            # 传送
	"mistfog": 1,             # 迷雾
	"stone_enchanted": 1,     # 石化附魔
	"wrath_of_god": 1,        # 神之愤怒
	"telekinesis": 1,         # 心灵感应
	"sacrifice": 1,           # 牺牲
	"holy_light": 1,          # 圣光
	"fireball": 1,            # 火球术
	"heal": 1,                # 治疗
	"fire_walk": 1,           # 火焰行走
	"meteor": 1,              # 陨石
	"armageddon": 1,          # 末日审判
	"freezing_spear": 1,      # 冰冻矛
	"poison_cloud": 1,        # 毒云
	"fortuna": 1,             # 幸运
	"dark_ritual": 1,         # 黑暗仪式
	"nova": 1,                # 新星
	"ball_lightning": 1,      # 球状闪电
	"chain_lightning": 1,     # 连锁闪电
}

# ============================================
# 生命值和法力值系统
# ============================================
# 原版数据参考 (extracted.md):
# STRENGTH_ON_HEALTH = 10, base=0
# INTELLIGENCE_ON_MANA = 6, base=0
# WISDOM_ON_MANA = 2, base=0
# STAMINA_ON_HEALTH_REGENERATION = 0.1, base=0
# INTELLIGENCE_ON_MANA_REGENERATION = 0.06, base=0
# WISDOM_ON_MANA_REGENERATION = 0.18, base=0

var health := 100.0       # 当前生命值
var max_health := 100.0   # 最大生命值（受力量影响）
var mana := 50.0          # 当前法力值
var max_mana := 50.0      # 最大法力值（受智力和智慧影响）

# 恢复计时器 - 用于控制每秒恢复频率
var health_regen_timer := 0.0
var mana_regen_timer := 0.0

# ============================================
# 受击恢复系统 (Hit Recovery)
# ============================================
# 原版数据: STRENGTH_ON_HIT_RECOVERY = -0.004, base=0.5
# 英雄被怪物成功攻击后进入受击恢复状态
# 在受击恢复期间：不能施法，移动速度降低20%

var hit_recovery_time := 0.5      # 当前受击恢复时间（秒）
var is_in_hit_recovery := false   # 是否处于受击恢复状态

# ============================================
# 被命中几率系统 (Chance To Be Hit)
# ============================================
# 原版数据: DEXTERITY_ON_CHANCE_TO_BE_HIT = -0.004, base=1.0
# 每点敏捷减少0.4%被命中率

var chance_to_be_hit := 1.0       # 被近战怪物命中的几率（1.0 = 100%）

var hero_save_position := Vector2(1280, 1280)  # 存档用的英雄位置

# ============================================
# Quest 进度存档系统
# ============================================
# 用于 Resume Game 功能，保存 Quest 模式的关卡进度
# 这些变量在 Quest 模式过关时自动保存
var quest_progress := {
	"current_level": 0,        # 当前关卡索引（0-9）
	"monsters_killed": 0,      # 本关已击杀怪物数
	"monsters_spawned": 0,     # 本关已生成怪物数
	"level_start_level": 1,    # 进入本关时的玩家等级
	"has_progress": false,     # 是否有有效的 Quest 进度
}

# 关卡解锁进度 - 记录玩家已解锁到第几关（0-9）
var quest_max_unlocked_level := 0

# Resume Game 标志 - 用于通知 QuestLevelManager 恢复进度
var is_resuming_quest := false

# 整个 Quest 过程中累计击杀总数（用于通关画面统计）
var quest_total_monsters_killed := 0

# 显示怪物信息（血条+伤害数字）— Alt键切换
var show_monster_info := false

# Survival 模式本轮累积获得的经验值（用于死亡统计）
var survival_total_exp_gained := 0

# 快捷技能槽位（空字符串 = 使用默认技能）
var quick_slot_lmb := ""   # 左键快捷槽位，默认 magic_missile
var quick_slot_rmb := ""   # 右键快捷槽位，默认 fireball
var quick_slot_shift := "" # Shift键快捷槽位
var quick_slot_space := "" # 空格键快捷槽位

# 鼠标是否悬停在 HUD 上（防止点击 HUD 时触发施法）
var is_mouse_over_hud := false

# ============================================
# Buff持续时间常量（原版数据）
# ============================================
const PHYSIC_RESIST_TIME := 15.0    # 物理抗性持续时间
const MAGIC_RESIST_TIME := 15.0     # 魔法抗性持续时间
const QUAD_DAMAGE_TIME := 15.0      # 四倍伤害持续时间
const SPEED_TIME := 15.0            # 加速持续时间
const IMMUNE_TIME := 15.0           # 无敌持续时间
const TIME_STOP_TIME := 15.0        # 时间停止持续时间

# ============================================
# Buff减伤系数（原版数据）
# ============================================
const PHYSIC_DAMAGE_REDUCTION := 0.2  # 物理减伤20%
const MAGIC_DAMAGE_REDUCTION := 0.2   # 魔法减伤20%

# ============================================
# Buff/Debuff 系统 - 统一管理所有临时效果
# ============================================
# 设计思路：
# - 所有临时效果（增益和减益）都通过 buff 系统管理
# - 每个 buff 有唯一ID、持续时间、参数和回调函数
# - 支持同类 buff 覆盖或叠加
# - 便于UI显示和扩展
#
# Buff 结构：
# {
#     "id": "buff_id",           # 唯一标识
#     "type": "buff"/"debuff",   # 类型
#     "duration": 5.0,           # 总持续时间
#     "remaining": 5.0,          # 剩余时间
#     "params": {},              # 自定义参数
#     "on_apply": Callable,      # 应用回调（可选）
#     "on_remove": Callable      # 移除回调（可选）
# }
# ============================================

# 当前激活的 buff 列表
var hero_buffs := {}

# 预定义的 buff 模板
const BUFF_TEMPLATES := {
	# 药水类 Buff
	"health_regen": {
		"type": "buff",
		"category": "regeneration",
		"description": "生命恢复"
	},
	"mana_regen": {
		"type": "buff",
		"category": "regeneration",
		"description": "法力恢复"
	},
	"speed_boost": {
		"type": "buff",
		"category": "movement",
		"description": "加速"
	},
	"damage_boost": {
		"type": "buff",
		"category": "combat",
		"description": "伤害提升"
	},
	"magic_shield": {
		"type": "buff",
		"category": "defense",
		"description": "魔法护盾"
	},
	"physic_shield": {
		"type": "buff",
		"category": "defense",
		"description": "物理护盾"
	},
	"free_spells": {
		"type": "buff",
		"category": "magic",
		"description": "免费施法"
	},
	"invulnerability": {
		"type": "buff",
		"category": "defense",
		"description": "无敌"
	},
	# Debuff 类
	"hit_slow": {
		"type": "debuff",
		"category": "movement",
		"description": "受击减速"
	},
	"time_stop": {
		"type": "buff",
		"category": "special",
		"description": "时间停止"
	},
	# 技能 buff
	"heal": {
		"type": "buff",
		"category": "regeneration",
		"description": "治疗术"
	},
	"prayer": {
		"type": "buff",
		"category": "regeneration",
		"description": "祈祷"
	}
}

# 兼容层 - 保留旧变量以便现有代码使用
# 这些变量会在 _process 中自动从 buff 系统同步
var damage_multiplier := 1.0     # 伤害倍率
var speed_multiplier := 1.0      # 速度倍率
var physic_resist := 0.0         # 物理抗性
var magic_resist := 0.0          # 魔法抗性
var free_spells := false         # 免费施法状态
var invulnerable := false        # 无敌状态
var drop_rate_multiplier := 1.0  # 掉落率倍率
var time_stop_active := false    # 时间停止状态

# ============================================
# 核心函数
# ============================================

func _ready():
	Engine.time_scale = 1.0

func _process(delta):
	# 每帧调用，处理生命和法力的自动恢复，以及buff更新
	# delta: 距离上一帧的时间（秒），用于保证恢复速率与帧率无关
	
	# 更新所有 buff
	_update_buffs(delta)
	
	# 累加计时器
	health_regen_timer += delta
	mana_regen_timer += delta
	
	# 计算实际恢复速率（受属性影响）
	# 原版公式：耐力每点增加0.1生命恢复/秒，基础0
	var health_regen_rate = hero_stamina * 0.1
	
	# 当计时器达到1/恢复速率时，恢复1点生命
	# 例如：恢复速率2.0，则每0.5秒恢复1点
	if health_regen_rate > 0 and health_regen_timer >= 1.0 / health_regen_rate and health < max_health:
		health = min(health + 1.0, max_health)  # min防止超过最大值
		health_regen_timer = 0.0
		health_changed.emit(health, max_health)  # 通知HUD更新显示
	
	# 法力恢复：智力0.06/点，智慧0.18/秒，基础0
	var mana_regen_rate = hero_intelligence * 0.06 + hero_wisdom * 0.18
	if mana_regen_rate > 0 and mana_regen_timer >= 1.0 / mana_regen_rate and mana < max_mana:
		mana = min(mana + 1.0, max_mana)
		mana_regen_timer = 0.0
		mana_changed.emit(mana, max_mana)

# ============================================
# 属性应用函数 - 加点后重新计算衍生属性
# ============================================

func apply_strength():
	# 力量影响最大生命值
	# 原版公式：STRENGTH_ON_HEALTH = 10, START_VALUE = 0
	# max_health = strength * 10
	max_health = hero_strength * 10.0
	health = min(health, max_health)
	health_changed.emit(health, max_health)
	
	# 力量也影响受击恢复时间
	# 原版公式：STRENGTH_ON_HIT_RECOVERY = -0.004, START_VALUE = 0.5
	# hit_recovery = 0.5 - strength * 0.004
	hit_recovery_time = max(0.1, 0.5 - hero_strength * 0.004)

func apply_dexterity():
	# 敏捷影响移动速度和被命中几率
	# 原版公式：DEXTERITY_ON_SPEED = 0.5, START_VALUE = 65
	# 原版公式：DEXTERITY_ON_CHANCE_TO_BE_HIT = -0.004, START_VALUE = 1
	# 每点敏捷减少0.4%被命中率
	chance_to_be_hit = max(0.04, 1.0 - hero_dexterity * 0.004)

func apply_stamina():
	# 耐力影响生命恢复和移动速度
	# 原版公式：STAMINA_ON_HEALTH_REGENERATION = 0.1, START_VALUE = 0
	# 原版公式：STAMINA_ON_SPEED = 0.35, START_VALUE = 0
	# 恢复在_process中计算
	pass

func apply_intelligence():
	# 智力影响最大法力值和法力恢复
	# 原版公式：INTELLIGENCE_ON_MANA = 6, START_VALUE = 0
	# 原版公式：INTELLIGENCE_ON_MANA_REGENERATION = 0.06, START_VALUE = 0
	max_mana = hero_intelligence * 6.0 + hero_wisdom * 2.0
	mana = min(mana, max_mana)
	mana_changed.emit(mana, max_mana)

func apply_wisdom():
	# 智慧影响法力值和法力恢复
	# 原版公式：WISDOM_ON_MANA = 2, START_VALUE = 0
	# 原版公式：WISDOM_ON_MANA_REGENERATION = 0.18, START_VALUE = 0
	apply_intelligence()

# ============================================
# 经验值和升级系统
# ============================================

func gain_experience(amount: int):
	# 增加经验值，处理升级逻辑
	# amount: 获得的经验值数量（原始值，Quest模式会减半）
	
	# Quest模式：检查等级上限（传入原始经验值）
	if current_game_mode == GameMode.QUEST:
		var level_manager = get_tree().get_first_node_in_group("quest_level_manager")
		if level_manager:
			if not level_manager.can_gain_experience(amount):
				# 已达到等级上限，不再获得经验
				print("Global: 已达到本关经验上限，不再获得经验！")
				return
		else:
			print("Global: gain_experience() - 未找到 level_manager！")
	
	# Quest模式：经验值减半
	var final_amount = amount
	if current_game_mode == GameMode.QUEST:
		final_amount = int(amount * 0.5)
	
	# Quest模式：记录本关获得的经验值（原始值）
	if current_game_mode == GameMode.QUEST:
		var level_manager = get_tree().get_first_node_in_group("quest_level_manager")
		if level_manager:
			level_manager.level_experience_gained += amount
			print("Global: Quest模式记录经验 +%d，本关总计=%d" % [amount, level_manager.level_experience_gained])
	
	# Survival模式：记录累积经验值（用于死亡统计）
	if current_game_mode == GameMode.SURVIVAL:
		survival_total_exp_gained += amount
	
	hero_experience += final_amount
	var exp_to_next = hero_level * 200  # 每级需要 等级×200 经验（简化公式）
	
	# 循环处理连续升级（可能一次获得大量经验连升多级）
	while hero_experience >= exp_to_next:
		hero_experience -= exp_to_next
		hero_level += 1
		attribute_points += 5      # 每级5点属性点（原版）
		skill_points += 1          # 每级1点技能点（原版）
		# 原版：升级时自动回满血和蓝
		health = max_health
		mana = max_mana
		print("Global: 升级！当前等级: %d" % hero_level)
		level_changed.emit(hero_level)
		exp_to_next = hero_level * 200
		
		# Quest模式：升级后检查是否达到经验上限
		if current_game_mode == GameMode.QUEST:
			var level_manager = get_tree().get_first_node_in_group("quest_level_manager")
			if level_manager and level_manager.has_method("check_level_limit"):
				print("Global: 升级后检查经验上限... 当前等级=%d" % hero_level)
				level_manager.check_level_limit()
	
	# 发射信号通知UI更新
	experience_changed.emit(hero_experience, hero_level * 200)
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)

# ============================================
# 伤害和治疗系统
# ============================================

func take_damage(amount: float, is_magic: bool = false, attacker: Node = null):
	if invulnerable:
		return

	if is_magic:
		amount *= (1.0 - magic_resist)
	else:
		amount *= (1.0 - physic_resist)

	health -= amount
	health_regen_timer = 0.0
	health_changed.emit(health, max_health)

	hero_took_damage.emit(amount, is_magic, attacker)

	if health <= 0:
		health = 0
		health_changed.emit(health, max_health)
		hero_died.emit()

func heal(amount: float):
	# 立即治疗
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func heal_over_time(amount: float, duration: float):
	# 持续治疗（如治疗技能）
	# amount: 总治疗量
	# duration: 持续时间（秒）
	
	var heal_per_second = amount / duration
	var tween = create_tween()
	tween.set_loops(int(duration))  # 循环duration次
	tween.tween_callback(func():
		health = min(health + heal_per_second, max_health)
		health_changed.emit(health, max_health)
	)
	tween.tween_interval(1.0)  # 每秒执行一次

func restore_mana(amount: float):
	# 立即恢复法力
	mana = min(mana + amount, max_mana)
	mana_changed.emit(mana, max_mana)

func restore_mana_over_time(amount: float, duration: float):
	# 持续恢复法力
	var mana_per_second = amount / duration
	var tween = create_tween()
	tween.set_loops(int(duration))
	tween.tween_callback(func():
		mana = min(mana + mana_per_second, max_mana)
		mana_changed.emit(mana, max_mana)
	)
	tween.tween_interval(1.0)

# ============================================
# Buff/Debuff 核心函数
# ============================================

func apply_buff(buff_id: String, duration: float, params: Dictionary = {}):
	# 应用一个 buff/debuff
	# buff_id: buff 标识符
	# duration: 持续时间（秒）
	# params: 自定义参数
	
	if not BUFF_TEMPLATES.has(buff_id):
		push_warning("Global: 未知的 buff ID: " + buff_id)
		return
	
	var template = BUFF_TEMPLATES[buff_id]
	
	# 创建 buff 实例
	var buff = {
		"id": buff_id,
		"type": template.type,
		"category": template.category,
		"description": template.description,
		"duration": duration,
		"remaining": duration,
		"params": params.duplicate()
	}
	
	# 存储到激活列表
	hero_buffs[buff_id] = buff
	
	# 立即应用效果
	_apply_buff_effect(buff_id, params)

func remove_buff(buff_id: String):
	# 手动移除一个 buff
	if not hero_buffs.has(buff_id):
		return
	
	var buff = hero_buffs[buff_id]
	_remove_buff_effect(buff_id, buff.params)
	hero_buffs.erase(buff_id)

func _update_buffs(delta: float):
	# 更新所有 buff 的剩余时间
	var expired_buffs := []
	
	for buff_id in hero_buffs.keys():
		var buff = hero_buffs[buff_id]
		buff.remaining -= delta
		
		# 处理持续恢复类 buff
		if buff_id == "health_regen" or buff_id == "heal":
			_regen_health_from_buff(buff, delta)
		elif buff_id == "mana_regen" or buff_id == "prayer":
			_regen_mana_from_buff(buff, delta)
		
		if buff.remaining <= 0:
			expired_buffs.append(buff_id)
	
	# 移除过期的 buff
	for buff_id in expired_buffs:
		remove_buff(buff_id)

func _regen_health_from_buff(buff: Dictionary, delta: float):
	# 从生命恢复 buff 中恢复生命
	if buff.params.has("percent_per_second"):
		var regen_amount = max_health * buff.params.percent_per_second * delta
		health = min(health + regen_amount, max_health)
		health_changed.emit(health, max_health)

func _regen_mana_from_buff(buff: Dictionary, delta: float):
	# 从法力恢复 buff 中恢复法力
	if buff.params.has("percent_per_second"):
		var regen_amount = max_mana * buff.params.percent_per_second * delta
		mana = min(mana + regen_amount, max_mana)
		mana_changed.emit(mana, max_mana)

func _apply_buff_effect(buff_id: String, params: Dictionary):
	# 应用 buff 效果到兼容层变量
	match buff_id:
		"speed_boost":
			if params.has("multiplier"):
				speed_multiplier = params.multiplier
		"damage_boost":
			if params.has("multiplier"):
				damage_multiplier = params.multiplier
		"magic_shield":
			if params.has("resist"):
				magic_resist = params.resist
		"physic_shield":
			if params.has("resist"):
				physic_resist = params.resist
		"free_spells":
			free_spells = true
		"invulnerability":
			invulnerable = true
		"time_stop":
			time_stop_active = true

func _remove_buff_effect(buff_id: String, _params: Dictionary):
	# 移除 buff 效果，重置兼容层变量
	match buff_id:
		"speed_boost":
			speed_multiplier = 1.0
		"damage_boost":
			damage_multiplier = 1.0
		"magic_shield":
			magic_resist = 0.0
		"physic_shield":
			physic_resist = 0.0
		"free_spells":
			free_spells = false
		"invulnerability":
			invulnerable = false
		"time_stop":
			time_stop_active = false

# ============================================
# Buff 兼容层 - 保留旧函数以便现有代码使用
# 这些函数现在内部调用新的 buff 系统
# ============================================

func activate_speed_boost(multiplier: float, duration: float):
	# 激活速度提升（通过 buff 系统）
	apply_buff("speed_boost", duration, {"multiplier": multiplier})

func activate_magic_shield(resist: float, duration: float):
	# 激活魔法护盾（通过 buff 系统）
	apply_buff("magic_shield", duration, {"resist": resist})

func activate_physic_shield(resist: float, duration: float):
	# 激活物理护盾（通过 buff 系统）
	apply_buff("physic_shield", duration, {"resist": resist})

func activate_damage_boost(multiplier: float, duration: float):
	# 激活伤害提升（通过 buff 系统）
	apply_buff("damage_boost", duration, {"multiplier": multiplier})

func activate_free_spells(duration: float):
	# 激活免费施法（通过 buff 系统）
	apply_buff("free_spells", duration)

func activate_invulnerability(duration: float):
	# 激活无敌状态（通过 buff 系统）
	apply_buff("invulnerability", duration)

# ============================================
# 重置函数 - 重新开始游戏时调用
# ============================================

func reset():
	# 重置所有数据到初始状态（原版初始值）
	hero_level = 1
	hero_experience = 0
	# 原版初始属性为10点
	hero_strength = 10
	hero_dexterity = 10
	hero_stamina = 10
	hero_intelligence = 10
	hero_wisdom = 10
	attribute_points = 0
	skill_points = 0
	survival_total_exp_gained = 0
	
	# 重置所有技能等级为0，然后设置初始技能
	for skill in skill_levels.keys():
		skill_levels[skill] = 0
	# 原版：初始magic missile为1级
	skill_levels["magic_missile"] = 1
	
	# 重新计算基础属性
	apply_strength()
	apply_dexterity()
	apply_intelligence()
	
	# 设置初始生命和法力（基于属性计算后）
	health = max_health
	mana = max_mana
	
	# 重置所有buff
	damage_multiplier = 1.0
	speed_multiplier = 1.0
	physic_resist = 0.0
	magic_resist = 0.0
	free_spells = false
	invulnerable = false
	drop_rate_multiplier = 1.0
	
	# 重置受击恢复状态
	is_in_hit_recovery = false
	
	# 重新应用被动技能效果
	Fortuna.update_drop_rate()
