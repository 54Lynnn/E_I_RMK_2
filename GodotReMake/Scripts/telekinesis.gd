extends Node

static var skill_name := "telekinesis"
static var skill_type := "active"  # 技能类型: active, toggle, passive
static var base_cooldown := 1.0
static var base_mana_cost := 0.0
static var pull_range := 300.0

static func get_mana_cost(_level: int) -> float:
	return 0.0  # 原版无消耗

static func get_pull_range(level: int) -> float:
	return pull_range + level * 20.0

static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	# Telekinesis 无消耗
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
