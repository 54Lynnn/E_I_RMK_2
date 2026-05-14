extends Area2D

const NovaProjScene = preload("res://Scenes/NovaProj.tscn")

static var skill_name := "nova"
static var skill_type := "active"
static var base_cooldown := 2.0
static var base_mana_cost := 45.0
static var base_damage := 200.0
static var damage_element := "water"

static func get_mana_cost(level: int) -> float:
	return 45.0 + (level - 1) * 2.0

static func get_damage(level: int) -> float:
	return 200.0 + (level - 1) * 10.0

static func get_radius(_level: int) -> float:
	return 100.0

static func get_freeze_duration(level: int) -> float:
	return 0.9 + level * 0.1  # LV1=1.0, LV10=1.9

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

		var muzzle = hero.get_node("Sprite2D/Muzzle")
		var proj = ObjectPool.get_object(NovaProjScene)
		proj.name = "nova_proj"
		proj.global_position = muzzle.global_position
		proj.direction = hero.global_position.direction_to(mouse_pos)
		proj.damage = get_damage(level)
		proj.explosion_radius = get_radius(level) * RelicManager.get_aoe_radius_multiplier()
		proj.freeze_duration = get_freeze_duration(level)
		hero.get_parent().add_child(proj)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false
