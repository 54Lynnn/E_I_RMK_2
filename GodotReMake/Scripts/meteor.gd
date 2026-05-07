extends Area2D

static var skill_name := "meteor"
static var base_cooldown := 12.0
static var base_mana_cost := 35.0
static var base_damage := 60.0
static var damage_element := "fire"

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 5.0

static func get_damage(level: int) -> float:
	return base_damage + level * 20.0

static func get_radius(level: int) -> float:
	return 60.0 + level * 4.0

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

		var meteor = preload("res://Scenes/Meteor.tscn").instantiate()
		meteor.global_position = mouse_pos - Vector2(0, 400)
		meteor.target_position = mouse_pos
		meteor.damage = get_damage(level)
		meteor.explosion_radius = get_radius(level)
		hero.get_parent().add_child(meteor)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

@export var damage := 60.0
@export var explosion_radius := 60.0
@export var fall_speed := 600.0

var target_position := Vector2.ZERO
var has_exploded := false

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "position", target_position - global_position, 0.5)
	tween.tween_callback(_explode)

func _explode():
	if has_exploded:
		return
	has_exploded = true

	if has_node("Sprite2D"):
		$Sprite2D.scale = Vector2(explosion_radius / 20.0, explosion_radius / 20.0)

	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if not is_instance_valid(m):
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= explosion_radius:
			if m.has_method("take_damage"):
				var damage_factor = 1.0 - (dist / explosion_radius) * 0.5
				m.take_damage(damage * damage_factor, damage_element)

	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(explosion_radius / 30.0, explosion_radius / 30.0)
	get_parent().add_child(explosion)

	await get_tree().create_timer(0.3).timeout
	queue_free()
