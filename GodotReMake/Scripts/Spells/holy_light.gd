extends Node2D

# ============================================
# Holy Light (圣光) - 技能配置
# ============================================
# 原版效果：从玩家位置向光标方向发射多道光线，呈扇形分布
# 光线同时发射，每道光线只命中第一个敌人，不穿透
# 伤害类型：air

static var skill_name := "holy_light"      # 技能唯一标识（必须和全局名称一致）
static var skill_type := "active"           # 技能类型: active, toggle, passive
static var base_cooldown := 1.0             # 基础冷却时间（秒）
static var base_mana_cost := 35.0           # 基础魔法消耗
static var base_damage := 120.0             # 基础伤害值
static var damage_element := "air"          # 伤害元素类型（air系技能）

# 光线数量配置
# LV1=3道, LV4=4道, LV7=5道, LV10=6道（原版数据）
static func get_beam_count(level: int) -> int:
	if level >= 10:
		return 7
	elif level >= 7:
		return 6
	elif level >= 4:
		return 5
	elif level >= 2:
		return 4
	return 3

static func get_damage(level: int) -> float:
	return 120.0 + (level - 1) * 5.56

static func get_mana_cost(level: int) -> float:
	return 35.0 + (level - 1) * 2.0

# ============================================
# 施法主函数
# ============================================
# 参数：
#   hero: 玩家节点
#   mouse_pos: 鼠标光标位置（世界坐标）
#   skill_cooldowns: 技能冷却字典
# 返回：
#   true=施法成功, false=施法失败（冷却中/魔法不足/未学习）
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	# 检查技能是否已学习
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	
	# 检查技能是否在冷却中
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	var mana_cost = get_mana_cost(level)

	# 检查魔法值是否足够（或者处于免费施法模式）
	if Global.free_spells or Global.mana >= mana_cost:
		# 扣除魔法值
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)

		# 获取发射位置（玩家枪口位置）
		var muzzle = hero.get_node("Sprite2D/Muzzle")
		
		# 计算基础方向：从玩家指向光标
		var base_direction = hero.global_position.direction_to(mouse_pos)
		
		# 获取当前等级的技能参数
		var beam_count = get_beam_count(level)    # 光线数量
		var damage = get_damage(level)             # 每道光线伤害
		
		# 扇形分布配置
		var spread_angle = deg_to_rad(60.0)        # 总扇形角度：60度（±30度）
		var start_angle = -spread_angle / 2.0      # 起始角度（左半边）
		var angle_step = spread_angle / max(beam_count - 1, 1)  # 每道光线间隔
		
		# 依次发射多道光线
		for i in range(beam_count):
			# 创建投射物
			var beam = preload("res://Scenes/Projectile.tscn").instantiate()
			
			# 设置发射位置
			beam.global_position = muzzle.global_position
			
			# 计算当前光线的方向（基础方向 + 扇形偏移）
			var angle = start_angle + angle_step * i
			beam.direction = base_direction.rotated(angle)
			
			# 投射物参数配置
			beam.speed = 750.0                       # 飞行速度：750（适中）
			beam.max_distance = 4000.0               # 最大射程：4000（覆盖全地图）
			beam.damage = damage                     # 伤害值
			beam.damage_element = damage_element     # 伤害类型：air
			beam.is_piercing = false                 # 不穿透：只命中第一个敌人
			# 注意：use_acceleration 默认 false，一出来就是全速
			
			# 设置贴图（使用HolyLight图标）
			if beam.has_node("Sprite2D") and ResourceLoader.exists("res://Art/Placeholder/HolyLight.png"):
				beam.get_node("Sprite2D").texture = load("res://Art/Placeholder/HolyLight.png")
			
			# 将投射物添加到场景中
			beam.name = "holy_light_proj"
			hero.get_parent().add_child(beam)

		# 设置技能冷却
		skill_cooldowns[skill_name] = base_cooldown
		return true
	
	# 魔法不足，施法失败
	return false
