extends Area2D

# ============================================
# FreezingSpear.gd - 冰冻矛专用脚本
# ============================================
# 冰冻矛特性：
# - 技能配置（冷却、伤害、法力消耗、冰冻时间）
# - 直线飞行，不跟踪，速度快
# - 穿透所有敌人（不销毁）
# - 造成伤害并冰冻敌人
# - 冰冻期间敌人不能移动、不能攻击
# ============================================

# ============================================
# 技能配置（从 hero.gd 迁移至此）
# ============================================
static var skill_name := "freezing_spear"
static var base_cooldown := 1.0
static var base_mana_cost := 10.0
static var base_damage := 10.0
static var damage_element := "water"

# 等级成长公式
static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 1.5  # LV1=15, LV10=25

static func get_damage(level: int) -> float:
	return base_damage + level * 5.0  # LV1=15, LV10=60

static func get_freeze_duration(level: int) -> float:
	return 1.0 + level * 0.1  # LV1=1s, LV10=2s

# 施法入口
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false
	
	var mana_cost = get_mana_cost(level)
	var damage = get_damage(level)
	var freeze_duration = get_freeze_duration(level)
	
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		
		var muzzle = hero.get_node("Sprite2D/Muzzle")
		var spear = preload("res://Scenes/FreezingSpear.tscn").instantiate()
		spear.global_position = muzzle.global_position
		spear.direction = hero.global_position.direction_to(mouse_pos)
		spear.damage = damage
		spear.freeze_duration = freeze_duration
		hero.get_parent().add_child(spear)
		print("Cast FreezingSpear at ", muzzle.global_position, " towards ", mouse_pos)
		
		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

# ============================================
# 实例属性（投射物行为）
# ============================================

# 基础速度（像素/秒）
@export var speed := 300.0

# 伤害值（由 cast 方法设置）
@export var damage := 5.0

# 冰冻时间（秒，由 cast 方法设置）
@export var freeze_duration := 1.0

# 最大飞行距离
@export var max_distance := 4000.0

# 最大存活时间（秒）
@export var max_lifetime := 10.0

# 内部变量
var direction := Vector2.RIGHT
var start_position := Vector2.ZERO
var life_time := 0.0
var hit_targets := []  # 记录已经命中过的目标，避免重复伤害

@onready var sprite := $Sprite2D

func _ready():
	start_position = global_position
	# 确保方向不为零
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	sprite.rotation = direction.angle()
	# 确保碰撞检测启用
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 4
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# 调试输出
	print("FreezingSpear created at ", global_position, " direction ", direction)

func _process(delta):
	life_time += delta
	
	# 超过最大存活时间则销毁
	if life_time > max_lifetime:
		destroy()
		return
	
	# 确保碰撞检测启用
	if not monitoring:
		monitoring = true
	
	# 直线飞行（恒定速度，无加速，无跟踪）
	var move = direction * speed * delta
	global_position += move
	
	# 调试输出位置
	if int(life_time * 10) % 5 == 0:
		print("FreezingSpear position: ", global_position)
	
	# 使用重叠检测来确保穿透所有敌人
	_check_collisions()
	
	# 超出最大距离则销毁
	if global_position.distance_to(start_position) > max_distance:
		destroy()

func _check_collisions():
	# 获取所有重叠的怪物
	var overlapping = get_overlapping_bodies()
	if overlapping.size() > 0:
		print("FreezingSpear overlapping bodies: ", overlapping.size())
	for body in overlapping:
		if body.is_in_group("monsters") and body.has_method("take_damage"):
			if body not in hit_targets:
				print("FreezingSpear hit monster: ", body.name)
				hit_targets.append(body)
				body.take_damage(damage, damage_element)
				_freeze_monster(body, freeze_duration)

func _on_body_entered(body):
	print("FreezingSpear body entered: ", body.name, " groups: ", body.get_groups())
	# 伤害逻辑已移至 _check_collisions，避免重复伤害

func _on_area_entered(area):
	print("FreezingSpear area entered: ", area.name, " groups: ", area.get_groups())
	# 伤害逻辑已移至 _check_collisions，避免重复伤害

func _freeze_monster(monster, duration: float):
	if not is_instance_valid(monster):
		return
	
	# 保存原始速度
	var original_speed = monster.move_speed if "move_speed" in monster else 65.0
	
	# 停止移动
	if "move_speed" in monster:
		monster.move_speed = 0.0
	
	# 禁止攻击
	var original_can_attack = monster.can_attack if "can_attack" in monster else true
	if "can_attack" in monster:
		monster.can_attack = false
	
	# 视觉反馈：变蓝
	if monster.has_node("Sprite2D"):
		monster.get_node("Sprite2D").modulate = Color(0.5, 0.8, 1.0)
	
	# 等待冰冻结束
	await get_tree().create_timer(duration).timeout
	
	# 恢复
	if is_instance_valid(monster):
		if "move_speed" in monster:
			monster.move_speed = original_speed
		if "can_attack" in monster:
			monster.can_attack = original_can_attack
		if monster.has_node("Sprite2D"):
			monster.get_node("Sprite2D").modulate = Color(1.0, 1.0, 1.0)

func destroy():
	print("FreezingSpear destroyed at ", global_position, " after ", life_time, " seconds")
	queue_free()
