extends Area2D

const ExplosionScene = preload("res://Scenes/Explosion.tscn")
const MissileScene = preload("res://Scenes/MagicMissile.tscn")

static var skill_name := "magic_missile"
static var skill_type := "active"
static var base_cooldown := 1.0
static var base_mana_cost := 5.0
static var base_damage := 5.0
static var damage_element := "basic"

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level

static func get_damage(level: int) -> float:
	var damage_per_level := [10.0, 10.0, 15.0, 20.0, 20.0, 25.0, 30.0, 30.0, 35.0, 35.0]
	return damage_per_level[clampi(level - 1, 0, 9)]

static func get_missile_count(level: int) -> int:
	if level >= 10:
		return 5
	elif level >= 8:
		return 4
	elif level >= 5:
		return 3
	elif level >= 2:
		return 2
	return 1

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

		for i in range(missile_count):
			var delay = i * 0.15
			var tween = hero.create_tween()
			tween.tween_interval(delay)
			tween.tween_callback(func():
				var current_mouse_pos = hero.get_global_mouse_position()
				var base_angle = hero.global_position.angle_to_point(current_mouse_pos)

				var missile = ObjectPool.get_object(MissileScene)
				missile.global_position = muzzle.global_position

				var spread = deg_to_rad(15.0)
				var angle = base_angle + randf_range(-spread, spread)
				missile.direction = Vector2(cos(angle), sin(angle))

				missile.damage = damage
				missile.initial_speed_factor = randf_range(0.1, 0.2)

				hero.get_parent().add_child(missile)
			)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

@export var speed := 500
@export var damage := 10.0
@export var max_distance := 4000
@export var max_lifetime := 10.0

@export var homing_strength := 2.5
@export var homing_range := 600.0

@export var initial_speed_factor := 0.15
@export var acceleration_time := 5

@export var min_turn_speed_factor := 0.1

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

func reset_for_pool():
	speed = 500
	damage = 10.0
	max_distance = 4000
	max_lifetime = 10.0
	homing_strength = 2.5
	homing_range = 600.0
	initial_speed_factor = 0.15
	acceleration_time = 5
	min_turn_speed_factor = 0.1
	direction = Vector2.RIGHT
	start_position = Vector2.ZERO
	life_time = 0.0
	previous_direction = Vector2.RIGHT
	monitoring = false

func _process(delta):
	if start_position == Vector2.ZERO:
		start_position = global_position
		direction = direction.normalized()

	if not monitoring:
		monitoring = true

	life_time += delta

	if life_time > max_lifetime:
		destroy()
		return

	var accel_progress = min(life_time / acceleration_time, 1.0)
	var current_speed_factor = initial_speed_factor + (1.0 - initial_speed_factor) * accel_progress

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

		var turn_angle = old_direction.angle_to(direction)
		var angle_deg = abs(rad_to_deg(turn_angle))
		var turn_sensitivity = 15.0
		var turn_factor = 1.0 - clamp(angle_deg * turn_sensitivity / 100.0, 0.0, 1.0 - min_turn_speed_factor)
		current_speed_factor *= turn_factor

	var current_speed = speed * current_speed_factor
	var move = direction * current_speed * delta
	global_position += move

	if global_position.distance_to(start_position) > max_distance:
		destroy()

func _on_body_entered(body):
	if body.is_in_group("monsters") and body.has_method("take_damage"):
		body.take_damage(damage, damage_element)
		if body.has_method("apply_debuff"):
			body.apply_debuff("slowed", 1.0, {"factor": 0.5}, "basic")
		if RelicManager.has_relic("knockback_missile"):
			_apply_knockback(body)
		destroy()
		return
	if body.is_in_group("walls"):
		destroy()

func _on_area_entered(area):
	if area.is_in_group("monsters") and area.get_parent().has_method("take_damage"):
		var monster = area.get_parent()
		monster.take_damage(damage, damage_element)
		if monster.has_method("apply_debuff"):
			monster.apply_debuff("slowed", 1.0, {"factor": 0.5}, "basic")
		if RelicManager.has_relic("knockback_missile"):
			_apply_knockback(monster)
		destroy()
		return

func _apply_knockback(monster: Node):
	if not monster or not is_instance_valid(monster):
		return
	var knock_dir = direction
	if knock_dir.length() < 0.1:
		knock_dir = Vector2.RIGHT
	if monster.has_method("apply_debuff"):
		monster.apply_debuff("stunned", 0.1, {}, "basic")
	if monster.has_method("set_knockback"):
		monster.set_knockback(knock_dir * 100.0, 0.1)

func destroy():
	var explosion = ObjectPool.get_object(ExplosionScene)
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	ObjectPool.return_to_pool(self)
