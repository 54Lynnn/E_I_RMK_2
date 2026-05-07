extends Node

static var skill_name := "telekinesis"
static var base_cooldown := 3.0
static var base_mana_cost := 10.0
static var pull_range := 300.0

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 2.0

static func get_pull_range(level: int) -> float:
	return pull_range + level * 20.0

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

		var range = get_pull_range(level)
		var items = hero.get_tree().get_nodes_in_group("items")
		var closest_item = null
		var closest_dist = range

		for item in items:
			if not is_instance_valid(item):
				continue
			var dist = hero.global_position.distance_to(item.global_position)
			if dist <= range and dist < closest_dist:
				closest_dist = dist
				closest_item = item

		if closest_item:
			var pull_strength = 600.0
			if closest_item.has_method("apply_pull"):
				closest_item.apply_pull(hero.global_position, pull_strength)
			else:
				var tween = closest_item.create_tween()
				tween.tween_property(closest_item, "global_position", hero.global_position, 0.3)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false
