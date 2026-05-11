extends Node2D

# ============================================
# Fireball (火球术) - 技能配置
# ============================================
# 原版效果：发射一个火球，命中敌人后爆炸，造成范围伤害
# 伤害类型：fire
# 使用 projectile.gd 实现投射物行为

static var skill_name := "fireball"      # 技能唯一标识
static var skill_type := "active"         # 技能类型: active, toggle, passive
static var base_cooldown := 0.5           # 基础冷却时间（秒）
static var base_mana_cost := 5.0          # 基础魔法消耗
static var base_damage := 40.0            # 基础伤害值
static var damage_element := "fire"       # 伤害元素类型（fire系技能）

# 爆炸半径配置
# LV1=60, LV10=70（原版数据，每级+1）
static func get_explosion_radius(level: int) -> float:
	return 60.0 + level * 1.0

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
		
		# 创建投射物（使用 Projectile.tscn）
		var fireball = preload("res://Scenes/Projectile.tscn").instantiate()
		fireball.global_position = muzzle.global_position
		fireball.direction = hero.global_position.direction_to(mouse_pos)
		fireball.speed = 300.0                     # 飞行速度
		fireball.max_distance = 4000.0             # 最大射程
		fireball.damage = damage                   # 直接命中伤害
		fireball.damage_element = damage_element   # 伤害类型：fire
		fireball.is_piercing = false               # 不穿透：命中后爆炸
		
		# 爆炸效果配置
		fireball.has_explosion = true              # 启用爆炸效果
		fireball.explosion_radius = explosion_radius  # 爆炸半径
		fireball.explosion_damage = damage         # 爆炸伤害
		
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
