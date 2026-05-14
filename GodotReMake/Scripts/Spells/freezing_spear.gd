extends Node2D

const ProjectileScene = preload("res://Scenes/Projectile.tscn")

# ============================================
# Freezing Spear (冰冻矛) - 技能配置
# ============================================
# 原版效果：依次发射多根矛，穿透敌人，造成伤害并冰冻
# 伤害类型：water
# 使用 projectile.gd 实现投射物行为

static var skill_name := "freezing_spear"   # 技能唯一标识
static var skill_type := "active"            # 技能类型: active, toggle, passive
static var base_cooldown := 1.0              # 基础冷却时间（秒）
static var base_mana_cost := 15.0            # 基础魔法消耗 (LV1=15)
static var base_damage := 5.0               # 基础伤害值
static var damage_element := "water"         # 伤害元素类型（water系技能）

# 矛数量配置
# LV1=1, LV3=2, LV5=3, LV8=4, LV10=5（原版数据）
static func get_spear_count(level: int) -> int:
	if level >= 10:
		return 5
	elif level >= 8:
		return 4
	elif level >= 5:
		return 3
	elif level >= 3:
		return 2
	else:
		return 1

# 冰冻持续时间配置
# LV1=4s, LV10=8.5s（原版数据，每级+0.5）
static func get_freeze_duration(level: int) -> float:
	return 3.5 + level * 0.5

# 伤害值配置
# 固定伤害 5（所有等级相同）
static func get_damage(_level: int) -> float:
	return 5.0

# 魔法消耗配置
# LV1=15, LV10=24（原版数据，每级+1）
static func get_mana_cost(level: int) -> float:
	return 14.0 + level * 1.0

# ============================================
# 施法主函数
# ============================================
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	# 检查技能是否已学习
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	
	# 检查技能是否在冷却中
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false
	
	var mana_cost = get_mana_cost(level)
	var damage = get_damage(level)
	var freeze_duration = get_freeze_duration(level)
	var spear_count = get_spear_count(level)
	
	# 检查魔法值是否足够
	if Global.free_spells or Global.mana >= mana_cost:
		# 扣除魔法值
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		
		# 依次发射多根矛，间隔0.2秒
		_spawn_spears_async(hero, mouse_pos, damage, freeze_duration, spear_count)
		
		# 设置技能冷却
		skill_cooldowns[skill_name] = base_cooldown
		return true
	
	# 魔法不足，施法失败
	return false

# 异步发射多根矛
# 注意：每根矛发射时都会重新获取鼠标实时位置，实现实时瞄准
static func _spawn_spears_async(hero: Node, mouse_pos: Vector2, damage: float, freeze_duration: float, count: int):
	var muzzle = hero.get_node("Sprite2D/Muzzle")
	
	for i in range(count):
		# 每次发射前重新获取鼠标实时位置（不是使用按下时的旧位置）
		# 注意：必须使用 get_global_mouse_position() 获取世界坐标
		# viewport.get_mouse_position() 返回的是视口坐标，会导致方向错误
		var current_mouse_pos = hero.get_global_mouse_position()
		var base_direction = hero.global_position.direction_to(current_mouse_pos)
		
		# 从对象池获取投射物
		var spear = ObjectPool.get_object(ProjectileScene)
		spear.global_position = muzzle.global_position
		
		# 所有矛完全指向鼠标实时方向（无角度偏移）
		# 如果想添加散布，取消注释下面两行：
		# var angle_offset = deg_to_rad((i - (count - 1) / 2.0) * 5.0)
		# spear.direction = base_direction.rotated(angle_offset)
		spear.direction = base_direction
		
		# 投射物参数配置
		spear.speed = 500.0                      # 飞行速度
		spear.max_distance = 4000.0              # 最大射程
		spear.damage = damage                    # 伤害值
		spear.damage_element = damage_element    # 伤害类型：water
		spear.is_piercing = true                 # 穿透：命中后继续飞行
		
		# 遗物：追踪冰冻之矛
		if RelicManager.has_relic("tracking_spear"):
			spear.has_homing = true
			spear.homing_strength = 1.0
			spear.homing_range = 350.0
		
		# 冰冻效果配置
		spear.has_freeze = true                  # 启用冰冻效果
		spear.freeze_duration = freeze_duration  # 冰冻持续时间
		
		# 设置贴图
		if spear.has_node("Sprite2D") and ResourceLoader.exists("res://Art/Placeholder/FreezingSpear.png"):
			spear.get_node("Sprite2D").texture = load("res://Art/Placeholder/FreezingSpear.png")
		
		# 添加到场景
		hero.get_parent().add_child(spear)
		
		# 等待0.2秒后发射下一根
		if i < count - 1:
			await hero.get_tree().create_timer(0.2).timeout
