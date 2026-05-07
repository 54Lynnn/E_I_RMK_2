extends Node

static var skill_name := "fortuna"
static var base_drop_rate_bonus := 0.5

static func get_drop_rate_bonus(level: int) -> float:
	return base_drop_rate_bonus + level * 0.15

static func cast(hero: Node, _mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	var bonus = get_drop_rate_bonus(level)
	Global.drop_rate_multiplier = 1.0 + bonus
	return true
