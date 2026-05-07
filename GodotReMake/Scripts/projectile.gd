extends Area2D

@export var speed := 10
@export var damage := 15.0
@export var damage_element := "basic"  # basic, earth, air, fire, water
@export var max_distance := 5000
@export var max_lifetime := 10.0      # 最大存活时间（秒）

# 跟踪系统（用于魔法飞弹）
@export var has_homing := false       # 是否开启跟踪
@export var homing_strength := 3.0    # 跟踪转向强度
@export var homing_range := 300.0     # 跟踪锁敌范围

# 加速系统（用于魔法飞弹，先慢后快）
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
	
	# 加速：初始速度慢，逐渐加速到全速
	var accel_progress = min(life_time / acceleration_time, 1.0)
	current_speed_factor = initial_speed_factor + (1.0 - initial_speed_factor) * accel_progress
	
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
		body.take_damage(damage * Global.damage_multiplier, damage_element)
		destroy()
	elif body.is_in_group("walls"):
		destroy()

func _on_area_entered(area):
	if area.is_in_group("monsters") and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage * Global.damage_multiplier, damage_element)
		destroy()

func destroy():
	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	queue_free()
