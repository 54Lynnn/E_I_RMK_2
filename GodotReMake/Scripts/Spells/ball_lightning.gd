extends Node2D

static var skill_name := "ball_lightning"
static var base_cooldown := 2.0
static var base_mana_cost := 45.0
static var base_damage := 200.0
static var damage_element := "air"
static var max_strikes := 5

static func get_mana_cost(level: int) -> float:
	return 45.0 + (level - 1) * 2.0

static func get_damage(level: int) -> float:
	return 200.0 + (level - 1) * 10.0

static func get_cooldown(level: int) -> float:
	return max(2.0 - (level - 1) * 0.1, 1.1)

static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	var mana_cost = get_mana_cost(level)
	if not (Global.free_spells or Global.mana >= mana_cost):
		return false

	if not Global.free_spells:
		Global.mana -= mana_cost
		Global.mana_changed.emit(Global.mana, Global.max_mana)

	var orb = preload("res://Scenes/BallLightning.tscn").instantiate()
	orb.name = "ball_lightning_proj"
	orb.global_position = mouse_pos
	orb.damage = get_damage(level)
	hero.get_parent().add_child(orb)

	skill_cooldowns[skill_name] = get_cooldown(level)
	return true

@export var damage := 200.0

var strikes_remaining := 5
var attack_cooldown := 0.0
var life_time := 0.0
var max_lifetime := 10.0
var spawn_position := Vector2.ZERO
var wander_target := Vector2.ZERO
var wander_radius := 130.0
var attack_range := 100.0
var attack_interval := 1.0

@onready var sprite := $Sprite2D

func _ready():
	spawn_position = global_position
	wander_target = _random_wander_pos()
	_apply_visual_style()

func _apply_visual_style():
	sprite.modulate = Color(0.5, 0.8, 1.0, 0.9)
	var base = sprite.scale
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "scale", base * 0.9, 0.5)
	tween.tween_property(sprite, "scale", base * 1.1, 0.5)

func _process(delta):
	if strikes_remaining <= 0 or life_time >= max_lifetime:
		_spawn_lightning_effect(global_position)
		queue_free()
		return

	life_time += delta
	attack_cooldown -= delta
	_wander(delta)

	if attack_cooldown <= 0:
		var target = _find_closest_enemy()
		if target != null:
			target.take_damage(damage, damage_element)
			strikes_remaining -= 1
			attack_cooldown = attack_interval
			_spawn_beam(target.global_position)

func _wander(delta):
	var dist_to_target = global_position.distance_to(wander_target)
	if dist_to_target < 20.0:
		wander_target = _random_wander_pos()
	var dir = global_position.direction_to(wander_target)
	global_position += dir * 60.0 * delta

func _random_wander_pos() -> Vector2:
	var angle = randf() * TAU
	var dist = randf() * wander_radius
	return spawn_position + Vector2(cos(angle), sin(angle)) * dist

func _find_closest_enemy():
	var monsters = get_tree().get_nodes_in_group("monsters")
	var closest = null
	var closest_dist = attack_range
	for m in monsters:
		if not is_instance_valid(m):
			continue
		if m.current_state == m.State.DEATH:
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = m
	return closest

func _spawn_beam(target_pos: Vector2):
	var beam = Line2D.new()
	beam.add_point(Vector2.ZERO)
	beam.add_point(to_local(target_pos))
	beam.default_color = Color(0.5, 0.8, 1.0, 0.9)
	beam.width = 3.0
	beam.antialiased = true
	add_child(beam)
	var btween = create_tween()
	btween.tween_property(beam, "default_color:a", 0.0, 0.2)
	btween.parallel().tween_property(beam, "width", 0.0, 0.2)
	btween.tween_callback(beam.queue_free)

func _spawn_lightning_effect(pos: Vector2):
	var bolt = Sprite2D.new()
	bolt.modulate = Color(0.5, 0.8, 1.0, 0.8)
	bolt.scale = Vector2(0.6, 0.6)
	bolt.global_position = pos
	get_parent().add_child(bolt)
	var btween = bolt.create_tween()
	btween.tween_property(bolt, "modulate:a", 0.0, 0.3)
	btween.tween_callback(bolt.queue_free)
