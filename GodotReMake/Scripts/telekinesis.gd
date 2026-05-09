extends Node

static var skill_name := "telekinesis"
static var skill_type := "passive"
static var base_cooldown := 0.0
static var base_mana_cost := 0.0

static func get_mana_cost(_level: int) -> float:
	return 0.0

static func cast(hero: Node, _mouse_pos: Vector2, _skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	return true
