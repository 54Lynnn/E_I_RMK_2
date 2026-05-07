extends Area2D

# ============================================
# Fireball.gd - 火球术专用脚本
# ============================================
# 火球术特性：
# - 技能配置（冷却、伤害、法力消耗、爆炸半径）
# - 直线飞行，不跟踪
# - 速度恒定（无加速）
# - 命中敌人后爆炸，造成范围伤害
# ============================================

# ============================================
# 技能配置（从 hero.gd 迁移至此）
# ============================================
static var skill_name := "fireball"
static var base_cooldown := 0.5
static var base_mana_cost := 5.0
static var base_damage := 40.0
static var damage_element := "fire"

# 等级成长公式
static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 1.0  # LV1=7, LV10=15

static func get_damage(level: int) -> float:
	return base_damage + level * 10.0  # LV1=50, LV10=140

static func get_explosion_radius(level: int) -> float:
	return 55.0 + level  # LV1=56, LV10=65

# 施法入口
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false
	
	var mana_cost = get_mana_cost(level)
	var damage = get_damage(level)
	var explosion_radius = get_explosion_radius(level)
	
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		
		var muzzle = hero.get_node("Sprite2D/Muzzle")
		var fireball = preload("res://Scenes/Fireball.tscn").instantiate()
		fireball.global_position = muzzle.global_position
		fireball.direction = hero.global_position.direction_to(mouse_pos)
		fireball.damage = damage
		fireball.explosion_damage = damage
		fireball.explosion_radius = explosion_radius
		hero.get_parent().add_child(fireball)
		
		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

# ============================================
# 实例属性（投射物行为）
# ============================================

# 基础速度（像素/秒）
@export var speed := 300.0

# 伤害值（由 cast 方法设置）
@export var damage := 15.0

# 爆炸范围伤害（由 cast 方法设置）
@export var explosion_radius := 50.0
@export var explosion_damage := 56.0

# 最大飞行距离
@export var max_distance := 4000

# 最大存活时间（秒）
@export var max_lifetime := 20

# 内部变量
var direction := Vector2.RIGHT
var start_position := Vector2.ZERO
var life_time := 0.0

@onready var sprite := $Sprite2D

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
	
	# 直线飞行（恒定速度，无加速，无跟踪）
	var move = direction * speed * delta
	global_position += move
	
	# 超出最大距离则销毁
	if global_position.distance_to(start_position) > max_distance:
		destroy()

func _on_body_entered(body):
	if body.is_in_group("monsters"):
		explode()
	elif body.is_in_group("walls"):
		destroy()

func _on_area_entered(area):
	if area.is_in_group("monsters"):
		explode()

func explode():
	# 对爆炸范围内的所有怪物造成伤害
	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if not is_instance_valid(m):
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= explosion_radius:
			if m.has_method("take_damage"):
				# 距离越近伤害越高
				var damage_factor = 1.0 - (dist / explosion_radius)
				var final_damage = explosion_damage + damage * damage_factor
				m.take_damage(final_damage, damage_element)
	
	# 创建爆炸特效
	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	# 调整爆炸大小
	explosion.scale = Vector2(explosion_radius / 30.0, explosion_radius / 30.0)
	get_parent().add_child(explosion)
	queue_free()

func destroy():
	queue_free()
