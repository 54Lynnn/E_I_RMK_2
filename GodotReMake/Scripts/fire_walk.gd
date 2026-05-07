extends Node2D

static var skill_name := "fire_walk"
static var base_cooldown := 10.0
static var base_mana_cost := 20.0
static var base_damage := 10.0
static var damage_element := "fire"
static var base_duration := 5.0
static var fire_interval := 0.5

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 3.0

static func get_damage(level: int) -> float:
	return base_damage + level * 4.0

static func get_duration(level: int) -> float:
	return base_duration + level * 0.5

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

		var fire_walk = preload("res://Scenes/FireWalk.tscn").instantiate()
		fire_walk.hero = hero
		fire_walk.damage = get_damage(level)
		fire_walk.duration = get_duration(level)
		hero.add_child(fire_walk)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

var hero: Node = null
var damage := 10.0
var duration := 5.0
var is_active := false
var last_fire_pos := Vector2.ZERO

func _ready():
	is_active = true
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_end)
	add_child(timer)
	timer.start()

func _process(_delta):
	if not is_active or hero == null:
		return
	var current_pos = hero.global_position
	if current_pos.distance_to(last_fire_pos) > 40.0:
		_spawn_fire(current_pos)
		last_fire_pos = current_pos

func _spawn_fire(pos: Vector2):
	var flame = Sprite2D.new()
	flame.global_position = pos
	flame.texture = preload("res://Art/Placeholder/FireWalk.png") if ResourceLoader.exists("res://Art/Placeholder/FireWalk.png") else null
	flame.modulate = Color(1.0, 0.3, 0.0, 0.8)
	flame.scale = Vector2(0.5, 0.5)
	get_parent().add_child(flame)

	var flame_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	flame_shape.shape = shape
	flame.add_child(flame_shape)

	var area = Area2D.new()
	flame.add_child(area)
	area.add_child(flame_shape.duplicate())
	area.collision_mask = 4

	var monsters_in_range = get_tree().get_nodes_in_group("monsters")
	for m in monsters_in_range:
		if is_instance_valid(m) and m.global_position.distance_to(pos) <= 20.0:
			if m.has_method("take_damage"):
				m.take_damage(damage, damage_element)

	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(flame, "modulate:a", 0.0, 0.5)
	tween.tween_callback(flame.queue_free)

func _on_end():
	is_active = false
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
