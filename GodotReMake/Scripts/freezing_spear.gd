extends Node2D

# ============================================
# Freezing Spear (冰冻矛) - 技能配置
# ============================================
# 原版效果：依次发射多根矛，穿透敌人，造成伤害并冰冻
# 伤害类型：water
# 使用 projectile.gd 实现投射物行为

static var skill_name := "freezing_spear"   # 技能唯一标识
static var skill_type := "active"            # 技能类型: active, toggle, passive
static var base_cooldown := 1.0              # 基础冷却时间（秒）
static var base_mana_cost := 10.0            # 基础魔法消耗
static var base_damage := 5.0               # 基础伤害值
static var damage_element := "water"         # 伤害元素类型（water系技能）

# 矛数量配置
# LV1=1, LV7=2, LV9=3（原版数据）
static func get_spear_count(level: int) -> int:
	if level >= 9:
		return 3
	elif level >= 7:
		return 2
	else:
		return 1

# 冰冻持续时间配置
# LV1=1s, LV10=2s（原版数据，每级+0.1）
static func get_freeze_duration(level: int) -> float:
	return 1.0 + level * 0.1

# 伤害值配置
# LV1=15, LV10=60（原版数据，每级+5）
static func get_damage(level: int) -> float:
	return base_damage + level * 5.0

# 魔法消耗配置
# LV1=15, LV10=25（原版数据，每级+1.5）
static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 1.5

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
static func _spawn_spears_async(hero: Node, mouse_pos: Vector2, damage: float, freeze_duration: float, count: int):
	var muzzle = hero.get_node("Sprite2D/Muzzle")
	var base_direction = hero.global_position.direction_to(mouse_pos)
	
	for i in range(count):
		# 创建投射物（使用 Projectile.tscn）
		var spear = preload("res://Scenes/Projectile.tscn").instantiate()
		spear.global_position = muzzle.global_position
		
		# 多根矛有轻微角度偏移（每根偏移5度）
		var angle_offset = deg_to_rad((i - (count - 1) / 2.0) * 5.0)
		spear.direction = base_direction.rotated(angle_offset)
		
		# 投射物参数配置
		spear.speed = 500.0                      # 飞行速度
		spear.max_distance = 4000.0              # 最大射程
		spear.damage = damage                    # 伤害值
		spear.damage_element = damage_element    # 伤害类型：water
		spear.is_piercing = true                 # 穿透：命中后继续飞行
		
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
