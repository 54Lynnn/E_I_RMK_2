extends Node

static var skill_name := "sacrifice"
static var base_cooldown := 10.0
static var base_mana_cost := 0.0
static var base_damage := 50.0
static var damage_element := "air"
static var health_cost_percent := 0.15

static func get_damage(level: int) -> float:
	return base_damage + level * 20.0

static func get_health_cost_percent(level: int) -> float:
	return max(health_cost_percent - level * 0.005, 0.05)

static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	var health_cost = Global.max_health * get_health_cost_percent(level)
	if Global.health <= health_cost:
		return false

	var damage = get_damage(level)
	Global.health -= health_cost
	Global.health_changed.emit(Global.health, Global.max_health)

	var monsters = hero.get_tree().get_nodes_in_group("monsters")
	var closest = null
	var closest_dist = 200.0
	for m in monsters:
		if not is_instance_valid(m):
			continue
		var dist = hero.global_position.distance_to(m.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = m

	if closest and closest.has_method("take_damage"):
		closest.take_damage(damage, damage_element)

	skill_cooldowns[skill_name] = base_cooldown
	return true
