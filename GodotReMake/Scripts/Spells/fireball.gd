extends Node2D

const ProjectileScene = preload("res://Scenes/Projectile.tscn")

static var skill_name := "fireball"
static var skill_type := "active"
static var base_cooldown := 0.5
static var base_mana_cost := 7.0
static var base_damage := 40.0
static var damage_element := "fire"

# 爆炸半径配置
# LV1=56, LV10=66（原版数据，每级+1）
static func get_explosion_radius(level: int) -> float:
	return 56.0 + level * 1.0

# 伤害值配置
# LV1=50, LV10=100（原版数据，每级+10）
static func get_damage(level: int) -> float:
	return base_damage + level * 10.0

# 魔法消耗配置
# 原版数据：固定 7 点 mana（所有等级相同）
static func get_mana_cost(_level: int) -> float:
	return 7.0

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
	var explosion_radius = get_explosion_radius(level)
	
	# 检查魔法值是否足够
	if Global.free_spells or Global.mana >= mana_cost:
		# 扣除魔法值
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		
		# 获取发射位置
		var muzzle = hero.get_node("Sprite2D/Muzzle")
		
		# 从对象池获取投射物
		var fireball = ObjectPool.get_object(ProjectileScene)
		fireball.global_position = muzzle.global_position
		fireball.direction = hero.global_position.direction_to(mouse_pos)
		fireball.speed = 300.0                     # 飞行速度
		fireball.max_distance = 4000.0             # 最大射程
		fireball.damage = damage                   # 直接命中伤害
		fireball.damage_element = damage_element   # 伤害类型：fire
		fireball.is_piercing = false               # 不穿透：命中后爆炸
		
		# 爆炸效果配置
		fireball.has_explosion = true              # 启用爆炸效果
		fireball.explosion_radius = explosion_radius * RelicManager.get_aoe_radius_multiplier()  # 爆炸半径
		fireball.explosion_damage = damage         # 爆炸伤害

		# 遗物：追踪火球术
		if RelicManager.has_relic("tracking_fireball"):
			fireball.has_homing = true
			fireball.homing_strength = 0.8
			fireball.homing_range = 350.0

		# 遗物：穿透火球术
		if RelicManager.has_relic("pierce_fireball"):
			fireball.is_piercing = true
			fireball.pierce_explosion = true
			fireball.explosion_radius *= RelicManager.get_aoe_radius_multiplier()
		
		# 设置贴图
		if fireball.has_node("Sprite2D") and ResourceLoader.exists("res://Art/Placeholder/Fireball.png"):
			fireball.get_node("Sprite2D").texture = load("res://Art/Placeholder/Fireball.png")
		
		# 添加到场景
		fireball.name = "fireball_proj"
		hero.get_parent().add_child(fireball)
		
		# 设置技能冷却
		skill_cooldowns[skill_name] = base_cooldown
		return true
	
	# 魔法不足，施法失败
	return false
