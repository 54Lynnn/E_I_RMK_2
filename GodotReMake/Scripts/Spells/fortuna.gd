extends Node

static var skill_name := "fortuna"
static var skill_type := "passive"

static func get_drop_rate_bonus(level: int) -> float:
	match level:
		1: return 0.15
		2: return 0.24
		3: return 0.32
		4: return 0.39
		5: return 0.45
		6: return 0.50
		7: return 0.54
		8: return 0.57
		9: return 0.59
		10: return 0.60
		_: return 0.0

static func update_drop_rate():
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		Global.drop_rate_multiplier = 1.0
		return
	var bonus = get_drop_rate_bonus(level)
	Global.drop_rate_multiplier = 1.0 + bonus

static func cast(hero: Node, _mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	update_drop_rate()
	return true
