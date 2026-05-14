extends Node

static var skill_name := "telekinesis"
static var skill_type := "passive"
static var base_cooldown := 0.0
static var base_mana_cost := 0.0

static func get_hold_time(level: int) -> float:
	match level:
		1: return 1.0
		2: return 0.91
		3: return 0.83
		4: return 0.76
		5: return 0.70
		6: return 0.65
		7: return 0.61
		8: return 0.58
		9: return 0.56
		10: return 0.55
		_: return 1.0

static func get_mana_cost(_level: int) -> float:
	return 0.0

static func cast(hero: Node, _mouse_pos: Vector2, _skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	return true
