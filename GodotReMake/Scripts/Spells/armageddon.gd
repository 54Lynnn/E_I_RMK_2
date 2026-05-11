extends Node2D

static var skill_name := "armageddon"
static var skill_type := "active"
static var base_cooldown := 20.0
static var base_mana_cost := 55.0
static var base_damage := 250.0
static var damage_element := "fire"

static func get_mana_cost(level: int) -> float:
	return 55.0 + (level - 1) * 3.0

static func get_damage(level: int) -> float:
	return 250.0 + (level - 1) * 10.0

static func get_cooldown(level: int) -> float:
	return max(20.0 - (level - 1) * 1.0, 11.0)

static func get_explosion_radius(_level: int) -> float:
	return 56.0

func _ready():
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

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

		var damage = get_damage(level)
		var explosion_radius = get_explosion_radius(level)
		var parent = hero.get_parent()
		var viewport = hero.get_viewport()
		var camera = viewport.get_camera_2d()
		var screen_center = camera.global_position
		var screen_size = viewport.get_visible_rect().size * camera.zoom
		var spawn_range = screen_size * 1.5

		var armageddon_zone = preload("res://Scenes/ArmageddonZone.tscn").instantiate()
		armageddon_zone.name = "armageddon_zone"
		armageddon_zone.global_position = hero.global_position
		armageddon_zone.damage = damage
		armageddon_zone.explosion_radius = explosion_radius
		armageddon_zone.damage_element = damage_element
		parent.add_child(armageddon_zone)

		var effect = preload("res://Scenes/Armageddon.tscn").instantiate()
		effect.global_position = hero.global_position
		parent.add_child(effect)

		skill_cooldowns[skill_name] = get_cooldown(level)
		return true
	return false
