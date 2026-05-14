extends Area2D

const ExplosionScene = preload("res://Scenes/Explosion.tscn")

@export var speed := 10
@export var damage := 15.0
@export var damage_element := "basic"
@export var max_distance := 5000
@export var max_lifetime := 10.0

@export var is_piercing := false
var hit_targets := []

@export var has_explosion := false
@export var explosion_radius := 50.0
@export var explosion_damage := 0.0

@export var pierce_explosion := false
var pierce_explosion_count := 0

@export var has_freeze := false
@export var freeze_duration := 1.0

@export var has_homing := false
@export var homing_strength := 3.0
@export var homing_range := 300.0

@export var use_acceleration := false
@export var initial_speed_factor := 0.05
@export var acceleration_time := 5

@export var turn_slowdown := true
@export var min_turn_speed_factor := 0.1
@export var turn_sensitivity := 10

var direction := Vector2.RIGHT
var start_position := Vector2.ZERO
var current_speed_factor := 0.0
var life_time := 0.0
var previous_direction := Vector2.RIGHT

@onready var sprite := $Sprite2D
@onready var particles := $Particles

func _ready():
	start_position = global_position
	direction = direction.normalized()
	sprite.rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func reset_for_pool():
	speed = 10
	damage = 15.0
	damage_element = "basic"
	max_distance = 5000
	max_lifetime = 10.0
	is_piercing = false
	hit_targets.clear()
	has_explosion = false
	explosion_radius = 50.0
	explosion_damage = 0.0
	pierce_explosion = false
	pierce_explosion_count = 0
	has_freeze = false
	freeze_duration = 1.0
	has_homing = false
	homing_strength = 3.0
	homing_range = 300.0
	use_acceleration = false
	initial_speed_factor = 0.05
	acceleration_time = 5
	turn_slowdown = true
	min_turn_speed_factor = 0.1
	turn_sensitivity = 10
	direction = Vector2.RIGHT
	start_position = Vector2.ZERO
	current_speed_factor = 0.0
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

	if use_acceleration:
		var accel_progress = min(life_time / acceleration_time, 1.0)
		current_speed_factor = initial_speed_factor + (1.0 - initial_speed_factor) * accel_progress
	else:
		current_speed_factor = 1.0

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

			if turn_slowdown:
				var turn_angle = old_direction.angle_to(direction)
				var turn_factor = 1.0 - clamp(abs(turn_angle) * turn_sensitivity, 0.0, 1.0 - min_turn_speed_factor)
				current_speed_factor *= turn_factor

	var current_speed = speed * current_speed_factor
	var move = direction * current_speed * delta
	global_position += move

	if global_position.distance_to(start_position) > max_distance:
		destroy()

func _on_body_entered(body):
	if body.is_in_group("monsters") and body.has_method("take_damage"):
		if body not in hit_targets:
			hit_targets.append(body)
			body.take_damage(damage * Global.damage_multiplier, damage_element)
			if has_freeze and body.has_method("apply_debuff"):
				body.apply_debuff("frozen", freeze_duration, {}, damage_element)
		if is_piercing and not pierce_explosion:
			return
		if pierce_explosion:
			pierce_explosion_count += 1
			var dmg = explosion_damage if explosion_damage > 0 else damage
			if pierce_explosion_count >= 2:
				dmg *= 0.5
			_do_explosion_at(global_position, dmg)
			if pierce_explosion_count >= 2:
				destroy()
			return
		if not is_piercing:
			if has_explosion:
				_explode()
			else:
				destroy()
	elif body.is_in_group("walls"):
		if pierce_explosion:
			var dmg = explosion_damage if explosion_damage > 0 else damage
			_do_explosion_at(global_position, dmg)
			destroy()
		elif has_explosion:
			_explode()
		else:
			destroy()

func _on_area_entered(area):
	if area.is_in_group("monsters") and area.get_parent().has_method("take_damage"):
		var target = area.get_parent()
		if target not in hit_targets:
			hit_targets.append(target)
			target.take_damage(damage * Global.damage_multiplier, damage_element)
			if has_freeze and target.has_method("apply_debuff"):
				target.apply_debuff("frozen", freeze_duration, {}, damage_element)
		if is_piercing and not pierce_explosion:
			return
		if pierce_explosion:
			pierce_explosion_count += 1
			var dmg = explosion_damage if explosion_damage > 0 else damage
			if pierce_explosion_count >= 2:
				dmg *= 0.5
			_do_explosion_at(global_position, dmg)
			if pierce_explosion_count >= 2:
				destroy()
			return
		if not is_piercing:
			if has_explosion:
				_explode()
			else:
				destroy()

func _explode():
	var dmg = explosion_damage if explosion_damage > 0 else damage
	_explosion_damage_at(global_position, explosion_radius, dmg, damage_element)

	var explosion = ObjectPool.get_object(ExplosionScene)
	explosion.global_position = global_position
	explosion.scale = Vector2(explosion_radius / 30.0, explosion_radius / 30.0)
	get_parent().add_child(explosion)
	if not is_piercing and not pierce_explosion:
		ObjectPool.return_to_pool(self)

func _do_explosion_at(pos: Vector2, dmg: float):
	_explosion_damage_at(pos, explosion_radius, dmg, damage_element)
	var explosion = ObjectPool.get_object(ExplosionScene)
	explosion.global_position = pos
	explosion.scale = Vector2(explosion_radius / 30.0, explosion_radius / 30.0)
	get_parent().add_child(explosion)

func _explosion_damage_at(pos: Vector2, radius: float, dmg: float, element: String):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	query.shape = circle
	query.transform = Transform2D(0, pos)
	query.collision_mask = 4
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body and body.is_in_group("monsters") and body not in hit_targets and body.has_method("take_damage"):
			body.take_damage(dmg * Global.damage_multiplier, element)

func destroy():
	var explosion = ObjectPool.get_object(ExplosionScene)
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	ObjectPool.return_to_pool(self)
