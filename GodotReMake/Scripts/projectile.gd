extends Area2D

@export var speed := 10
@export var damage := 15.0
@export var damage_element := "basic"  # basic, earth, air, fire, water
@export var max_distance := 5000
@export var max_lifetime := 10.0      # 最大存活时间（秒）

# 穿透系统
@export var is_piercing := false      # 是否穿透敌人（不销毁）
var hit_targets := []                 # 已命中的目标（避免重复伤害）

# 爆炸效果（用于 Fireball）
@export var has_explosion := false    # 是否启用爆炸效果
@export var explosion_radius := 50.0  # 爆炸半径
@export var explosion_damage := 0.0   # 爆炸伤害（0表示使用damage）

# 冰冻效果（用于 Freezing Spear）
@export var has_freeze := false       # 是否启用冰冻效果
@export var freeze_duration := 1.0    # 冰冻持续时间（秒）

# 跟踪系统（用于魔法飞弹）
@export var has_homing := false       # 是否开启跟踪
@export var homing_strength := 3.0    # 跟踪转向强度
@export var homing_range := 300.0     # 跟踪锁敌范围

# 加速系统（用于魔法飞弹，先慢后快）
# 注意：默认禁用加速。只有 magic_missile 需要设置为 true
@export var use_acceleration := false      # 是否使用逐渐加速（默认禁用）
@export var initial_speed_factor := 0.05  # 初始速度为最终速度的百分比
@export var acceleration_time := 5     # 加速到全速需要的时间（秒）

# 转弯减速系统（原版魔法飞弹特性）
@export var turn_slowdown := true     # 是否开启转弯减速
@export var min_turn_speed_factor := 0.1  # 转弯时的最小速度系数
@export var turn_sensitivity := 10   # 转弯减速敏感度

var direction := Vector2.RIGHT
var start_position := Vector2.ZERO
var current_speed_factor := 0.0
var life_time := 0.0
var previous_direction := Vector2.RIGHT  # 上一帧的方向，用于计算转弯角度

@onready var sprite := $Sprite2D
@onready var particles := $Particles

func _ready():
	start_position = global_position
	direction = direction.normalized()
	sprite.rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta):
	life_time += delta
	
	# 超过最大存活时间则销毁
	if life_time > max_lifetime:
		destroy()
		return
	
	# 加速：初始速度慢，逐渐加速到全速（如果启用）
	if use_acceleration:
		var accel_progress = min(life_time / acceleration_time, 1.0)
		current_speed_factor = initial_speed_factor + (1.0 - initial_speed_factor) * accel_progress
	else:
		current_speed_factor = 1.0  # 立即全速
	
	# 跟踪系统：如果开启跟踪，寻找附近最近的怪物并转向它
	if has_homing:
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
			if turn_slowdown:
				var turn_angle = old_direction.angle_to(direction)
				var turn_factor = 1.0 - clamp(abs(turn_angle) * turn_sensitivity, 0.0, 1.0 - min_turn_speed_factor)
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
		# 避免重复伤害同一目标
		if body not in hit_targets:
			hit_targets.append(body)
			body.take_damage(damage * Global.damage_multiplier, damage_element)
			# 冰冻效果
			if has_freeze and body.has_method("apply_debuff"):
				body.apply_debuff("frozen", freeze_duration)
		# 非穿透模式下触发爆炸或销毁
		if not is_piercing:
			if has_explosion:
				_explode()
			else:
				destroy()
	elif body.is_in_group("walls"):
		if has_explosion:
			_explode()
		else:
			destroy()

func _on_area_entered(area):
	if area.is_in_group("monsters") and area.get_parent().has_method("take_damage"):
		var target = area.get_parent()
		# 避免重复伤害同一目标
		if target not in hit_targets:
			hit_targets.append(target)
			target.take_damage(damage * Global.damage_multiplier, damage_element)
			# 冰冻效果
			if has_freeze and target.has_method("apply_debuff"):
				target.apply_debuff("frozen", freeze_duration)
		# 非穿透模式下触发爆炸或销毁
		if not is_piercing:
			if has_explosion:
				_explode()
			else:
				destroy()

func _explode():
	# 爆炸效果：对范围内的所有敌人造成一致伤害
	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if not is_instance_valid(m):
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= explosion_radius:
			if m.has_method("take_damage"):
				# 范围内伤害一致（无距离衰减）
				var final_damage = explosion_damage if explosion_damage > 0 else damage
				m.take_damage(final_damage, damage_element)
	
	# 创建爆炸特效
	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(explosion_radius / 30.0, explosion_radius / 30.0)
	get_parent().add_child(explosion)
	queue_free()

func destroy():
	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	queue_free()
