extends Area2D

static var skill_name := "nova"
static var base_cooldown := 10.0
static var base_mana_cost := 30.0
static var base_damage := 20.0
static var damage_element := "water"

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 5.0

static func get_damage(level: int) -> float:
	return base_damage + level * 8.0

static func get_radius(level: int) -> float:
	return 80.0 + level * 5.0

static func cast(hero: Node, _mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
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

		var nova = preload("res://Scenes/Nova.tscn").instantiate()
		nova.global_position = hero.global_position
		nova.damage = get_damage(level)
		nova.radius = get_radius(level)
		hero.get_parent().add_child(nova)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

@export var damage := 20.0
@export var radius := 80.0

func _ready():
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = radius
	$Sprite2D.scale = Vector2(radius / 40.0, radius / 40.0)
	$Sprite2D.modulate = Color(0.5, 0.8, 1.0, 0.8)

	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if not is_instance_valid(m):
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= radius and m.has_method("take_damage"):
			var damage_factor = 1.0 - (dist / radius) * 0.3
			m.take_damage(damage * damage_factor, damage_element)

	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(radius / 30.0, radius / 30.0)
	get_parent().add_child(explosion)

	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(radius / 40.0 * 1.5, radius / 40.0 * 1.5), 0.2)
	tween.parallel().tween_property($Sprite2D, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
