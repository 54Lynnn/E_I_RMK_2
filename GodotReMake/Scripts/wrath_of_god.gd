extends Node2D

static var skill_name := "wrath_of_god"
static var skill_type := "active"  # 技能类型: active, toggle, passive
static var base_cooldown := 2.0
static var base_mana_cost := 55.0
static var base_damage := 200.0
static var damage_element := "earth"

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 2.5  # LV1=55, LV10=80 (原版数据)

static func get_damage(level: int) -> float:
	return base_damage + level * 15.0  # LV1=200, LV10=275 (原版数据)

static func get_cooldown(level: int) -> float:
	return max(base_cooldown - level * 0.1, 1.5)  # LV1=2s, LV10=1.5s (原版数据)

static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	var mana_cost = get_mana_cost(level)

	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)

		var damage = get_damage(level)
		var radius = 200.0  # 调整后的射程（原版130，我们的比例不同用200）
		
		# 向10个方向发射锤子（每36度一个方向）
		for i in range(10):
			var angle = deg_to_rad(i * 36.0)
			var direction = Vector2(cos(angle), sin(angle))
			
			# 创建锤子投射物
			var hammer = preload("res://Scenes/Projectile.tscn").instantiate()
			hammer.global_position = hero.global_position
			hammer.direction = direction
			hammer.speed = 3000.0  # 极快的速度
			hammer.max_distance = radius
			hammer.damage = damage
			hammer.damage_element = damage_element
			hammer.is_piercing = true  # 锤子穿透所有敌人
			# 使用WrathOfGod贴图
			if hammer.has_node("Sprite2D") and ResourceLoader.exists("res://Art/Placeholder/WrathOfGod.png"):
				hammer.get_node("Sprite2D").texture = load("res://Art/Placeholder/WrathOfGod.png")
			hero.get_parent().add_child(hammer)
		
		# 中心视觉效果
		var effect = Sprite2D.new()
		if ResourceLoader.exists("res://Art/Placeholder/WrathOfGod.png"):
			effect.texture = load("res://Art/Placeholder/WrathOfGod.png")
		effect.global_position = hero.global_position
		effect.modulate = Color(0.8, 0.6, 0.2, 0.9)
		effect.scale = Vector2(2, 2)
		hero.get_parent().add_child(effect)
		var etween = effect.create_tween()
		etween.tween_property(effect, "modulate:a", 0.0, 0.5)
		etween.tween_callback(effect.queue_free)

		skill_cooldowns[skill_name] = get_cooldown(level)
		return true
	return false
