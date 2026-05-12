extends Area2D

static var skill_name := "meteor"
static var skill_type := "active"
static var base_cooldown := 5.0
static var base_mana_cost := 45.0
static var base_damage := 250.0
static var damage_element := "fire"

static func get_mana_cost(level: int) -> float:
	return 45.0 + (level - 1) * 2.0

static func get_damage(level: int) -> float:
	return 250.0 + (level - 1) * 10.0

static func get_cooldown(level: int) -> float:
	return max(5.0 - (level - 1) * 0.2, 3.2)

static func get_radius(_level: int) -> float:
	return 130.0

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

		var meteor_zone = preload("res://Scenes/Meteor.tscn").instantiate()
		meteor_zone.name = "meteor_zone"
		meteor_zone.global_position = mouse_pos
		meteor_zone.damage = get_damage(level)
		meteor_zone.zone_radius = get_radius(level)
		hero.get_parent().add_child(meteor_zone)

		skill_cooldowns[skill_name] = get_cooldown(level)
		return true
	return false

@export var damage := 250.0
@export var zone_radius := 130.0
@export var meteor_explosion_radius := 56.0
@export var duration := 3.0
@export var drop_interval := 0.2
@export var meteors_per_drop := 2

var life_time := 0.0
var drop_timer := 0.0

func _ready():
	z_index = 5

	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = zone_radius

	var boundary = Line2D.new()
	boundary.name = "Boundary"
	boundary.width = 2.0
	boundary.default_color = Color(1.0, 0.4, 0.0, 0.8)
	var points = []
	var segments = 64
	for i in range(segments + 1):
		var angle = float(i) / segments * TAU
		points.append(Vector2(cos(angle), sin(angle)) * zone_radius)
	boundary.points = points
	add_child(boundary)

	var icon_size = zone_radius * sqrt(2)
	$Sprite2D.scale = Vector2(icon_size / 64.0, icon_size / 64.0)

	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, duration)
	tween.parallel().tween_property(boundary, "modulate:a", 0.0, duration)

func _process(delta):
	life_time += delta
	drop_timer += delta

	if drop_timer >= drop_interval:
		drop_timer = 0.0
		for i in range(meteors_per_drop):
			_spawn_meteor()

	if life_time >= duration:
		queue_free()

func _spawn_meteor():
	var random_offset = Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized() * randf() * zone_radius
	var target_pos = global_position + random_offset

	var meteor = preload("res://Scenes/MeteorSingle.tscn").instantiate()
	meteor.name = "meteor_proj"
	meteor.global_position = target_pos + Vector2(0, -300)
	meteor.target_position = target_pos
	meteor.damage = damage
	meteor.explosion_radius = meteor_explosion_radius
	meteor.damage_element = damage_element
	get_parent().add_child(meteor)
