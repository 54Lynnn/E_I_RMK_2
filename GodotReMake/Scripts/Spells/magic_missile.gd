extends Area2D

# ============================================
# MagicMissile.gd - 魔法飞弹专用脚本
# ============================================
# 这是魔法飞弹的独立控制脚本，包含：
# - 技能配置（冷却、伤害、法力消耗、弹数）
# - 跟踪系统（自动追踪附近怪物）
# - 加速系统（先慢后快）
# - 转弯减速（转向时速度降低）
# - 生命周期管理（10秒自动销毁）
# ============================================

# ============================================
# 技能配置（从 hero.gd 迁移至此）
# ============================================
static var skill_name := "magic_missile"
static var skill_type := "active"  # 技能类型: active, toggle, passive
static var base_cooldown := 1.0
static var base_mana_cost := 5.0
static var base_damage := 5.0
static var damage_element := "basic"  # basic, earth, air, fire, water

# 等级成长公式
static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level  # LV1=6, LV10=15

static func get_damage(level: int) -> float:
	return base_damage + level * 5.0  # LV1=10, LV10=35

static func get_missile_count(level: int) -> int:
	# 原版数据: LV1=1, LV2=2, LV3=2, LV5=3, LV8=4, LV10=5
	if level >= 10:
		return 5
	elif level >= 8:
		return 4
	elif level >= 5:
		return 3
	elif level >= 2:
		return 2
	return 1

# 施法入口
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false
	
	var mana_cost = get_mana_cost(level)
	var damage = get_damage(level)
	var missile_count = get_missile_count(level)
	
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		
		var muzzle = hero.get_node("Sprite2D/Muzzle")
		
		# 依次发射飞弹，间隔0.15秒
		# 这样满级5发时：0s, 0.15s, 0.3s, 0.45s, 0.6s 发射完毕
		# CD为1秒，两次发射之间有0.4秒间隔
		for i in range(missile_count):
			var delay = i * 0.15
			var tween = hero.create_tween()
			tween.tween_interval(delay)
			tween.tween_callback(func():
				# 每次发射前重新获取鼠标实时位置（不是使用按下时的旧位置）
				# 注意：必须使用 get_global_mouse_position() 获取世界坐标
				# viewport.get_mouse_position() 返回的是视口坐标，会导致方向错误
				var current_mouse_pos = hero.get_global_mouse_position()
				var base_angle = hero.global_position.angle_to_point(current_mouse_pos)
				
				var missile = preload("res://Scenes/MagicMissile.tscn").instantiate()
				missile.name = "magic_missile_proj"
				missile.global_position = muzzle.global_position
				
				# 方向随机散布：在基础角度上偏移 ±15度
				# 如果想调整散布范围，修改 deg_to_rad() 里的数值
				var spread = deg_to_rad(15.0)
				var angle = base_angle + randf_range(-spread, spread)
				missile.direction = Vector2(cos(angle), sin(angle))
				
				missile.damage = damage
				
				# 初始速度随机化：每发飞弹的初始速度为最终速度的 10%~20%
				# 这样视觉上每发飞弹的起步速度略有不同，更有变化感
				# 如果想调整范围，修改 randf_range() 里的数值
				missile.initial_speed_factor = randf_range(0.1, 0.2)
				
				hero.get_parent().add_child(missile)
			)
		
		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

# ============================================
# 实例属性（投射物行为）
# ============================================

# 基础速度（像素/秒）
@export var speed := 500

# 伤害值（由 cast 方法设置）
@export var damage := 10.0

# 最大飞行距离
@export var max_distance := 4000

# 最大存活时间（秒）
@export var max_lifetime := 10.0

# 跟踪系统
@export var homing_strength := 2.5    # 跟踪转向强度
@export var homing_range := 600.0     # 跟踪锁敌范围

# 加速系统（先慢后快）
# 默认备用值为0.15，实际在 cast 方法中被随机覆盖为 0.1~0.2
# 如果想调整随机范围，去 cast 方法里修改 randf_range(0.1, 0.2)
@export var initial_speed_factor := 0.15  # 初始速度为最终速度的百分比
@export var acceleration_time := 5     # 加速到全速需要的时间（秒）

# 转弯减速系统
@export var min_turn_speed_factor := 0.1  # 转弯时的最小速度系数
@export var turn_sensitivity := 6.0       # 转弯减速敏感度

# 内部变量
var direction := Vector2.RIGHT
var start_position := Vector2.ZERO
var life_time := 0.0
var previous_direction := Vector2.RIGHT

@onready var sprite := $Sprite2D
@onready var particles := $Particles

func _ready():
	start_position = global_position
	direction = direction.normalized()
	previous_direction = direction
	sprite.rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta):
	life_time += delta
	
	# 超过最大存活时间则销毁
	if life_time > max_lifetime:
		destroy()
		return
	
	# 加速：初始速度慢，逐渐加速到全速
	var accel_progress = min(life_time / acceleration_time, 1.0)
	var current_speed_factor = initial_speed_factor + (1.0 - initial_speed_factor) * accel_progress
	
	# 跟踪系统：寻找附近最近的怪物并转向它
	var monsters = get_tree().get_nodes_in_group("monsters")
	var closest = null
	var closest_dist = homing_range
	for m in monsters:
		if not is_instance_valid(m):
			continue
		var dist = global_position.distance_squared_to(m.global_position)
		if dist < closest_dist * closest_dist:
			closest_dist = sqrt(dist)
			closest = m
	
	if closest:
		var target_dir = global_position.direction_to(closest.global_position)
		var old_direction = direction
		direction = direction.lerp(target_dir, homing_strength * delta).normalized()
		sprite.rotation = direction.angle()
		
		# 转弯减速：转向角度越大，速度越慢
		# 线性公式：turn_factor = 1.0 - clamp(angle * sensitivity, 0.0, max_slowdown)
		# 当前设置：5度→25%, 6.7度以上→10%
		# 想调整小转弯减速程度，修改 turn_sensitivity；想调整最低速度，修改 min_turn_speed_factor
		var turn_angle = old_direction.angle_to(direction)
		var angle_deg = abs(rad_to_deg(turn_angle))  # 弧度转角度
		var turn_sensitivity = 15.0  # 敏感度：越大减速越剧烈
		var min_turn_speed_factor = 0.1  # 最低保留速度：10%
		var turn_factor = 1.0 - clamp(angle_deg * turn_sensitivity / 100.0, 0.0, 1.0 - min_turn_speed_factor)
		current_speed_factor *= turn_factor
	
	var current_speed = speed * current_speed_factor
	
	# 移动
	var move = direction * current_speed * delta
	global_position += move
	
	# 超出最大距离则销毁
	if global_position.distance_to(start_position) > max_distance:
		destroy()

func _on_body_entered(body):
	if body.is_in_group("monsters") and body.has_method("take_damage"):
		body.take_damage(damage, damage_element)
		# 【减速效果】命中后减速50%，持续1秒
		if body.has_method("apply_debuff"):
			body.apply_debuff("slowed", 1.0, {"factor": 0.5}, "basic")
		destroy()
		return
	if body.is_in_group("walls"):
		destroy()

func _on_area_entered(area):
	if area.is_in_group("monsters") and area.get_parent().has_method("take_damage"):
		var monster = area.get_parent()
		monster.take_damage(damage, damage_element)
		# 【减速效果】命中后减速50%，持续1秒
		if monster.has_method("apply_debuff"):
			monster.apply_debuff("slowed", 1.0, {"factor": 0.5}, "basic")
		destroy()
		return

func destroy():
	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	queue_free()
