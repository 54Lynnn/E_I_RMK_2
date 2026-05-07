extends Area2D

static var skill_name := "dark_ritual"
static var base_cooldown := 20.0
static var base_mana_cost := 40.0
static var base_damage := 100.0
static var damage_element := "water"
static var base_delay := 2.0

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 5.0

static func get_damage(level: int) -> float:
	return base_damage + level * 30.0

static func get_delay(level: int) -> float:
	return max(base_delay - level * 0.1, 0.5)

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

		var ritual = preload("res://Scenes/DarkRitual.tscn").instantiate()
		ritual.global_position = mouse_pos
		ritual.damage = get_damage(level)
		ritual.delay = get_delay(level)
		ritual.radius = 60.0 + level * 3.0
		hero.get_parent().add_child(ritual)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

@export var damage := 100.0
@export var delay := 2.0
@export var radius := 60.0

func _ready():
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = radius
	$Sprite2D.scale = Vector2(radius / 30.0, radius / 30.0)
	$Sprite2D.modulate = Color(0.3, 0.1, 0.5, 0.6)

	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 1.0, delay * 0.5)
	tween.tween_interval(delay * 0.5)
	tween.tween_callback(_explode)
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _explode():
	var overlapping = get_overlapping_bodies()
	for body in overlapping:
		if body.is_in_group("monsters") and body.has_method("take_damage"):
			body.take_damage(damage, damage_element)

	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
