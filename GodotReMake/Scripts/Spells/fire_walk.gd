extends Node2D

static var skill_name := "fire_walk"
static var skill_type := "toggle"
static var base_cooldown := 1.0
static var base_mana_cost := 0.0
static var base_damage := 30.0
static var damage_element := "fire"

static func get_damage(level: int) -> float:
	return 30.0 + (level - 1) * 5.0

static func get_mana_cost(_level: int) -> float:
	return 0.0

static func cast(hero: Node, _mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false

	var existing = hero.get_node_or_null("FireWalkEffect")
	if existing:
		existing.deactivate()
		return true

	var fire_walk = preload("res://Scenes/FireWalk.tscn").instantiate()
	fire_walk.name = "FireWalkEffect"
	fire_walk.hero = hero
	fire_walk.damage = get_damage(level)
	hero.add_child(fire_walk)
	return true

var hero: Node = null
var damage := 30.0
var is_active := false
var last_fire_pos := Vector2.ZERO
var _current_radius := 18.0
const FIRE_INTERVAL := 30.0
const BASE_FIRE_RADIUS := 18.0
const FIRE_DURATION := 2.0
const TICK_INTERVAL := 0.1

func _ready():
	is_active = true
	last_fire_pos = hero.global_position if hero else Vector2.ZERO
	_current_radius = BASE_FIRE_RADIUS * RelicManager.get_aoe_radius_multiplier()

func _process(delta):
	if not is_active or hero == null:
		return
	var current_pos = hero.global_position
	var dist = current_pos.distance_to(last_fire_pos)
	if dist >= FIRE_INTERVAL:
		_spawn_fire(current_pos)
		last_fire_pos = current_pos

func deactivate():
	is_active = false
	queue_free()

func _spawn_fire(pos: Vector2):
	var fire_area = Area2D.new()
	fire_area.name = "fire_walk_zone"
	fire_area.global_position = pos
	fire_area.collision_layer = 0
	fire_area.collision_mask = 4
	fire_area.z_index = 5

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = _current_radius
	collision.shape = shape
	fire_area.add_child(collision)

	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://Art/Placeholder/FireWalk.png"):
		sprite.texture = load("res://Art/Placeholder/FireWalk.png")
		sprite.scale = Vector2(0.35, 0.35)
	else:
		var cr = int(_current_radius)
		var img = Image.create(cr * 2, cr * 2, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for x in range(cr * 2):
			for y in range(cr * 2):
				var dx = x - cr
				var dy = y - cr
				if dx * dx + dy * dy <= cr * cr:
					img.set_pixel(x, y, Color(1.0, 0.3, 0.0, 0.8))
		sprite.texture = ImageTexture.create_from_image(img)
	sprite.modulate = Color.WHITE
	sprite.z_index = 5
	fire_area.add_child(sprite)

	hero.get_parent().add_child(fire_area)
	fire_area.process_mode = PROCESS_MODE_ALWAYS

	var damage_timer = Timer.new()
	damage_timer.wait_time = TICK_INTERVAL
	damage_timer.autostart = true
	fire_area.add_child(damage_timer)

	var damage_per_tick = damage * TICK_INTERVAL
	var total_ticks = int(FIRE_DURATION / TICK_INTERVAL)
	var tick_count = 0

	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = FIRE_DURATION
	cleanup_timer.one_shot = true
	fire_area.add_child(cleanup_timer)
	cleanup_timer.start()

	var element = damage_element
	var tree = get_tree()

	damage_timer.timeout.connect(func():
		tick_count += 1
		if tick_count > total_ticks:
			return
		var bodies = fire_area.get_overlapping_bodies()
		for m in bodies:
			if is_instance_valid(m) and m.is_in_group("monsters"):
				if m.has_method("take_damage"):
					m.take_damage(damage_per_tick, element)
	)

	cleanup_timer.timeout.connect(func():
		damage_timer.stop()
		var tween = tree.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func():
			if is_instance_valid(fire_area):
				fire_area.queue_free()
		)
	)
