extends Node2D

# ============================================
# Fire Walk (火焰行走) - 技能配置
# ============================================
# 原版效果：Toggle 技能，开启后移动时留下火焰轨迹
# 每移动 50px 留下一个火焰区域，半径 30，持续 3 秒
# 每秒造成 30 火焰伤害（对范围内的敌人）
# 伤害类型：fire

static var skill_name := "fire_walk"       # 技能唯一标识
static var skill_type := "toggle"           # 技能类型: active, toggle, passive
static var base_cooldown := 1.0             # 基础冷却时间（秒）- Toggle 技能冷却短
static var base_mana_cost := 20.0           # 基础魔法消耗（开启时消耗）
static var base_damage := 30.0              # 基础伤害值（每秒伤害）
static var damage_element := "fire"         # 伤害元素类型（fire系技能）

# 伤害值配置
# LV1=30, LV10=70（原版数据，每级+4）
static func get_damage(level: int) -> float:
	return 30.0 + (level - 1) * 5.0

static func get_mana_cost(level: int) -> float:
	return 20.0 + (level - 1) * 3.0

# ============================================
# 施法主函数（Toggle）
# ============================================
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	# 检查技能是否已学习
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	
	# 检查技能是否在冷却中
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	# 检查是否已经有 Fire Walk 实例在运行
	var existing = hero.get_node_or_null("FireWalkEffect")
	if existing:
		# 关闭 Fire Walk
		existing.deactivate()
		skill_cooldowns[skill_name] = base_cooldown
		return true

	var mana_cost = get_mana_cost(level)

	# 检查魔法值是否足够
	if Global.free_spells or Global.mana >= mana_cost:
		# 扣除魔法值
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)

		# 创建 Fire Walk 效果实例
		print("Fire Walk creating instance")
		var fire_walk = preload("res://Scenes/FireWalk.tscn").instantiate()
		fire_walk.name = "FireWalkEffect"
		fire_walk.hero = hero
		fire_walk.damage = get_damage(level)       # 每秒伤害
		hero.add_child(fire_walk)
		print("Fire Walk instance added to hero")

		# 设置技能冷却
		skill_cooldowns[skill_name] = base_cooldown
		return true
	
	# 魔法不足，施法失败
	return false

# ============================================
# 实例属性（火焰轨迹效果）
# ============================================
var hero: Node = null                        # 玩家节点引用
var damage := 30.0                           # 每秒伤害值
var is_active := false                       # 是否激活
var last_fire_pos := Vector2.ZERO            # 上次留下火焰的位置
const FIRE_INTERVAL := 50.0                  # 每移动 50px 留下一个火焰

func _ready():
	is_active = true
	last_fire_pos = hero.global_position if hero else Vector2.ZERO
	print("Fire Walk _ready called, hero: ", hero, " pos: ", last_fire_pos)

func _process(delta):
	if not is_active or hero == null:
		return
	
	# 检查移动距离
	var current_pos = hero.global_position
	var dist = current_pos.distance_to(last_fire_pos)
	
	# 每移动 50px 留下一个火焰
	if dist >= FIRE_INTERVAL:
		print("Fire Walk spawning fire at: ", current_pos, " dist: ", dist)
		_spawn_fire(current_pos)
		last_fire_pos = current_pos

func deactivate():
	# 关闭 Fire Walk
	is_active = false
	queue_free()

func _spawn_fire(pos: Vector2):
	# 创建火焰区域（地面效果）
	var fire_area = Area2D.new()
	fire_area.name = "fire_walk_zone"          # 节点名称，方便调试
	fire_area.global_position = pos
	fire_area.collision_layer = 0              # 不与其他物体碰撞
	fire_area.collision_mask = 4               # 只检测怪物层
	fire_area.z_index = 5                      # 地面效果层级
	
	# 添加碰撞形状（圆形区域）
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30.0                        # 原版半径 30
	collision.shape = shape
	fire_area.add_child(collision)
	
	# 添加视觉效果
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://Art/Placeholder/FireWalk.png"):
		sprite.texture = load("res://Art/Placeholder/FireWalk.png")
		# 缩放贴图以适应半径 30 的圆形（假设贴图是 64x64）
		sprite.scale = Vector2(1.0, 1.0)
	else:
		# 如果没有专用贴图，使用一个简单的圆形代替
		var img = Image.create(60, 60, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))  # 透明背景
		# 绘制橙红色圆形
		for x in range(60):
			for y in range(60):
				var dx = x - 30
				var dy = y - 30
				if dx * dx + dy * dy <= 900:  # 半径30的圆
					img.set_pixel(x, y, Color(1.0, 0.3, 0.0, 0.8))
		sprite.texture = ImageTexture.create_from_image(img)
	# 使用白色 modulate，让贴图原色显示（贴图本身应该是火焰效果）
	sprite.modulate = Color.WHITE
	sprite.z_index = 5  # 确保精灵也在正确的层级
	fire_area.add_child(sprite)
	
	# 添加到场景（使用 hero 的父节点，确保火焰在世界坐标中）
	hero.get_parent().add_child(fire_area)
	
	# 持续伤害：每秒对范围内的敌人造成伤害
	var damage_timer = Timer.new()
	damage_timer.wait_time = 1.0  # 每秒伤害一次
	damage_timer.autostart = true
	fire_area.add_child(damage_timer)
	
	# 伤害逻辑
	var damage_count = 0
	var max_damage_ticks = 3  # 持续3秒，每秒1次，共3次伤害
	
	var _on_damage_tick = func():
		damage_count += 1
		if damage_count > max_damage_ticks:
			damage_timer.stop()
			return
		
		# 对范围内的敌人造成伤害
		var monsters = get_tree().get_nodes_in_group("monsters")
		for m in monsters:
			if is_instance_valid(m) and m.global_position.distance_to(pos) <= 30.0:
				if m.has_method("take_damage"):
					m.take_damage(damage, damage_element)
	
	damage_timer.timeout.connect(_on_damage_tick)
	
	# 3 秒后消失
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	
	var _on_fade_out = func():
		damage_timer.stop()
		fire_area.queue_free()
	
	tween.tween_callback(_on_fade_out)