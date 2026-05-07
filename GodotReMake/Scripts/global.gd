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

# 开发者模式开关 - 开启后按T键可获得大量属性点和技能点
var dev_mode := false

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

# ============================================
# 基础属性 - 玩家等级和经验
# ============================================

var hero_level := 1        # 当前等级，初始为1
var hero_experience := 0   # 当前经验值，升级需要 hero_level * 100 点经验

# ============================================
# 属性点系统 - 五大基础属性
# ============================================
# 每次升级获得5点属性点，可在英雄面板分配

var hero_strength := 10       # 力量：影响最大生命值
var hero_dexterity := 10      # 敏捷：影响移动速度和闪避
var hero_stamina := 10        # 耐力：影响生命恢复速度
var hero_intelligence := 10   # 智力：影响最大法力值和法力恢复
var hero_wisdom := 10         # 智慧：影响法力恢复速度

var attribute_points := 0     # 当前可用的属性点数
var skill_points := 0         # 当前可用的技能点数

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
	"magic_missile": 1,       # 魔法飞弹 - 默认已学习（1级）
	"prayer": 1,              # 祈祷
	"teleport": 1,            # 传送
	"mistfog": 1,             # 迷雾
	"stone_enchanted": 1,     # 石化附魔
	"wrath_of_god": 1,        # 神之愤怒
	"telekinesis": 1,         # 心灵感应
	"sacrifice": 1,           # 牺牲
	"holy_light": 1,          # 圣光
	"ball_lightning": 1,      # 球状闪电
	"chain_lightning": 1,     # 连锁闪电
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
}



# 最大技能等级常量
const MAX_SKILL_LEVEL := 10

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

# 基础恢复速率（每秒恢复点数）
const BASE_HEALTH_REGEN := 1.0
const BASE_MANA_REGEN := 1.0

# ============================================
# 受击恢复系统 (Hit Recovery)
# ============================================
# 原版数据: STRENGTH_ON_HIT_RECOVERY = -0.004, base=0.5

# 当前受击恢复时间（秒），受力量影响
var hit_recovery_time := 0.5

# ============================================
# 被命中几率系统 (Chance To Be Hit)
# ============================================
# 原版数据: DEXTERITY_ON_CHANCE_TO_BE_HIT = -0.004, base=1.0
# 每点敏捷减少0.4%被命中率，最低5%，最高96%

var chance_to_be_hit := 1.0

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
# Buff/状态系统 - 临时增益效果
# ============================================

var damage_multiplier := 1.0     # 伤害倍率（药水效果）
var speed_multiplier := 1.0      # 速度倍率（药水效果）
var physic_resist := 0.0         # 物理抗性（0-1）
var magic_resist := 0.0          # 魔法抗性（0-1）
var free_spells := false         # 免费施法状态
var invulnerable := false        # 无敌状态
var drop_rate_multiplier := 1.0  # 掉落率倍率

# 时间停止状态（某些技能效果）
var time_stop_active := false

# ============================================
# 核心函数
# ============================================

func _ready():
	# 节点初始化时调用，当前无需特殊处理
	pass

func _process(delta):
	# 每帧调用，处理生命和法力的自动恢复
	# delta: 距离上一帧的时间（秒），用于保证恢复速率与帧率无关
	
	# 累加计时器
	health_regen_timer += delta
	mana_regen_timer += delta
	
	# 计算实际恢复速率（受属性影响）
	# 耐力每点增加0.1生命恢复/秒
	var health_regen_rate = BASE_HEALTH_REGEN + hero_stamina * 0.1
	
	# 当计时器达到1/恢复速率时，恢复1点生命
	# 例如：恢复速率2.0，则每0.5秒恢复1点
	if health_regen_timer >= 1.0 / health_regen_rate and health < max_health:
		health = min(health + 1.0, max_health)  # min防止超过最大值
		health_regen_timer = 0.0
		health_changed.emit(health, max_health)  # 通知HUD更新显示
	
	# 法力恢复：智力0.06/点，智慧0.18/点
	var mana_regen_rate = BASE_MANA_REGEN + hero_intelligence * 0.06 + hero_wisdom * 0.18
	if mana_regen_timer >= 1.0 / mana_regen_rate and mana < max_mana:
		mana = min(mana + 1.0, max_mana)
		mana_regen_timer = 0.0
		mana_changed.emit(mana, max_mana)

# ============================================
# 属性应用函数 - 加点后重新计算衍生属性
# ============================================

func apply_strength():
	# 力量影响最大生命值
	# 原版公式：STRENGTH_ON_HEALTH = 10, base=0
	# max_health = 100 + strength * 10
	max_health = 100.0 + hero_strength * 10.0
	health = min(health, max_health)
	health_changed.emit(health, max_health)
	
	# 力量也影响受击恢复时间
	# 原版公式：hit_recovery = 0.5 - strength * 0.004
	hit_recovery_time = max(0.1, 0.5 - hero_strength * 0.004)

func apply_dexterity():
	# 敏捷影响移动速度（在hero.gd中计算）和被命中几率
	# 原版公式：chance = max(0.05, min(0.96, 1.0 - dexterity * 0.009))
	chance_to_be_hit = max(0.05, min(0.96, 1.0 - hero_dexterity * 0.009))

func apply_stamina():
	# 耐力影响生命恢复（在_process中计算）
	pass

func apply_intelligence():
	# 智力影响最大法力值
	# 公式：基础50 + 智力 × 6 + 智慧 × 2
	max_mana = 50.0 + hero_intelligence * 6.0 + hero_wisdom * 2.0
	mana = min(mana, max_mana)
	mana_changed.emit(mana, max_mana)

func apply_wisdom():
	# 智慧影响法力恢复和最大法力值
	apply_intelligence()

# ============================================
# 经验值和升级系统
# ============================================

func gain_experience(amount: int):
	# 增加经验值，处理升级逻辑
	# amount: 获得的经验值数量
	
	hero_experience += amount
	var exp_to_next = hero_level * 100  # 每级需要 等级×100 经验
	
	# 循环处理连续升级（可能一次获得大量经验连升多级）
	while hero_experience >= exp_to_next:
		hero_experience -= exp_to_next
		hero_level += 1
		attribute_points += 5      # 每级5点属性点
		skill_points += 1          # 每级1点技能点
		max_health += 20.0         # 每级+20最大生命
		health = max_health        # 升级回满血
		max_mana += 10.0           # 每级+10最大法力
		mana = max_mana            # 升级回满蓝
		level_changed.emit(hero_level)
		exp_to_next = hero_level * 100
	
	# 发射信号通知UI更新
	experience_changed.emit(hero_experience, hero_level * 100)
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)

# ============================================
# 伤害和治疗系统
# ============================================

func take_damage(amount: float, is_magic: bool = false):
	# 英雄受到伤害
	# amount: 伤害数值
	# is_magic: 是否为魔法伤害（影响抗性计算）
	
	if invulnerable:
		return  # 无敌状态不受伤害
	
	# 应用抗性减免
	if is_magic:
		amount *= (1.0 - magic_resist)
	else:
		amount *= (1.0 - physic_resist)
	
	health -= amount
	health_regen_timer = 0.0  # 受伤重置恢复计时器
	health_changed.emit(health, max_health)
	
	if health <= 0:
		health = 0
		health_changed.emit(health, max_health)
		hero_died.emit()  # 发射死亡信号

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
# Buff激活函数 - 各种临时增益效果
# ============================================

func activate_speed_boost(multiplier: float, duration: float):
	# 激活速度提升
	# multiplier: 速度倍率（如2.0表示双倍速度）
	# duration: 持续时间（秒）
	
	speed_multiplier = multiplier
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		# 只有当当前倍率等于激活时的倍率才重置（防止覆盖）
		if speed_multiplier == multiplier:
			speed_multiplier = 1.0
	)

func activate_magic_shield(resist: float, duration: float):
	# 激活魔法护盾
	magic_resist = resist
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if magic_resist == resist:
			magic_resist = 0.0
	)

func activate_physic_shield(resist: float, duration: float):
	# 激活物理护盾
	physic_resist = resist
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if physic_resist == resist:
			physic_resist = 0.0
	)

func activate_damage_boost(multiplier: float, duration: float):
	# 激活伤害提升
	damage_multiplier = multiplier
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if damage_multiplier == multiplier:
			damage_multiplier = 1.0
	)

func activate_free_spells(duration: float):
	# 激活免费施法（不消耗法力）
	free_spells = true
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if free_spells:
			free_spells = false
	)

func activate_invulnerability(duration: float):
	# 激活无敌状态
	invulnerable = true
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if invulnerable:
			invulnerable = false
	)

# ============================================
# 重置函数 - 重新开始游戏时调用
# ============================================

func reset():
	# 重置所有数据到初始状态
	hero_level = 1
	hero_experience = 0
	hero_strength = 10
	hero_dexterity = 10
	hero_stamina = 10
	hero_intelligence = 10
	hero_wisdom = 10
	attribute_points = 0
	skill_points = 0
	
	# 重置所有技能等级为1（方便测试）
	for skill in skill_levels.keys():
		skill_levels[skill] = 1
	
	max_health = 100.0
	health = max_health
	max_mana = 50.0
	mana = max_mana
	
	# 重置所有buff
	damage_multiplier = 1.0
	speed_multiplier = 1.0
	physic_resist = 0.0
	magic_resist = 0.0
	free_spells = false
	invulnerable = false
