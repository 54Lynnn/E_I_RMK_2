extends Node2D

# ============================================
# Sacrifice (牺牲) - 技能配置
# ============================================
# 原版效果：消耗生命值，秒杀光标 50 范围内最近的单体敌人
# 伤害类型：air
# 秒杀概率：100%（对没有 air aura 的敌人）
# 注意：这是 air 系技能，对没有 air aura 的敌人造成 99999 伤害（秒杀）
# 范围限制：只搜索光标 50 范围内的敌人

static var skill_name := "sacrifice"
static var skill_type := "active"
static var base_cooldown := 3.0
static var base_mana_cost := 0.0
static var base_damage := 50.0
static var damage_element := "air"
static var health_cost_percent := 0.55

static func get_damage(level: int) -> float:
	return base_damage + level * 20.0

static func get_health_cost_percent(level: int) -> float:
	return max(0.55 - (level - 1) * 0.05, 0.10)

static func get_cooldown(level: int) -> float:
	return max(3.0 - (level - 1) * 0.2, 1.2)

# ============================================
# 施法主函数
# ============================================
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	# 检查技能是否已学习
	var level = Global.skill_levels.get(skill_name, 0)
	print("Sacrifice cast - level: ", level)
	if level <= 0:
		print("Sacrifice failed: level <= 0")
		return false
	
	# 检查技能是否在冷却中
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		print("Sacrifice failed: cooldown ", skill_cooldowns[skill_name])
		return false

	# 计算生命值消耗
	var health_cost = Global.max_health * get_health_cost_percent(level)
	print("Sacrifice health_cost: ", health_cost, " current health: ", Global.health)
	
	# 检查生命值是否足够（至少保留1点生命）
	if Global.health <= health_cost:
		print("Sacrifice failed: not enough health")
		return false

	# 寻找光标 50 范围内最近的敌人
	var search_radius = 50.0  # 搜索范围半径
	var monsters = hero.get_tree().get_nodes_in_group("monsters")
	var closest = null
	var closest_dist = search_radius  # 初始距离设为搜索半径
	
	print("Sacrifice searching monsters: ", monsters.size(), " at mouse_pos: ", mouse_pos)
	
	for m in monsters:
		if not is_instance_valid(m):
			continue
		# 计算敌人到光标的距离
		var dist = m.global_position.distance_to(mouse_pos)
		print("Sacrifice monster dist: ", dist, " pos: ", m.global_position)
		# 只考虑在搜索范围内的敌人
		if dist <= search_radius and dist < closest_dist:
			closest_dist = dist
			closest = m

	# 如果找到目标，执行秒杀
	if closest and closest.has_method("take_damage"):
		print("Sacrifice target found: ", closest.name)
		# 创建剑刺特效
		_spawn_sword_effect(hero, closest)
		
		# 消耗生命值
		Global.health -= health_cost
		Global.health_changed.emit(Global.health, Global.max_health)
		
		# 【光环系统】检查目标是否有 air aura
		# air aura 敌人完全抵抗 Sacrifice（造成0伤害）
		if closest.get("elemental_aura") == "air":
			closest.take_damage(0.0, damage_element)
		else:
			# 100% 秒杀：造成 99999 伤害（确保秒杀）
			closest.take_damage(99999.0, damage_element)
	else:
		print("Sacrifice: no target found in range")

	# 设置技能冷却（无论是否找到目标都进入冷却）
	skill_cooldowns[skill_name] = get_cooldown(level)
	print("Sacrifice cooldown set")
	return true

# 创建剑刺特效
static func _spawn_sword_effect(hero: Node, target: Node):
	# 创建剑的精灵
	var sword = Sprite2D.new()
	if ResourceLoader.exists("res://Art/Placeholder/Sacrifice.png"):
		sword.texture = load("res://Art/Placeholder/Sacrifice.png")
	else:
		# 如果没有专用贴图，使用一个简单的矩形代替
		var img = Image.create(10, 40, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.8, 0.8, 0.9, 1.0))  # 银白色
		sword.texture = ImageTexture.create_from_image(img)
	
	# 设置初始位置（玩家位置上方）
	sword.global_position = hero.global_position + Vector2(0, -50)
	sword.rotation = -PI / 2  # 剑尖朝上
	
	# 添加到场景
	hero.get_parent().add_child(sword)
	
	# 计算剑刺向目标的方向
	var target_pos = target.global_position
	var direction = sword.global_position.direction_to(target_pos)
	
	# 创建动画：剑刺向目标
	var tween = sword.create_tween()
	
	# 第一阶段：剑旋转指向目标
	var target_rotation = direction.angle() + PI / 2
	tween.tween_property(sword, "rotation", target_rotation, 0.1)
	
	# 第二阶段：剑刺向目标
	tween.tween_property(sword, "global_position", target_pos, 0.15)
	
	# 第三阶段：剑穿过目标并消失
	tween.tween_property(sword, "modulate:a", 0.0, 0.2)
	tween.tween_callback(sword.queue_free)
