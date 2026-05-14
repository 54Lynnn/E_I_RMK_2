extends Node

static var skill_name := "stone_enchanted"
static var skill_type := "passive"  # 技能类型: active, toggle, passive
static var base_petrify_chance := 0.15

static func get_petrify_chance(level: int) -> float:
	return min(0.15 + (level - 1) * 0.05, 0.60)

static func get_petrify_duration(_level: int) -> float:
	return 1.0

static func cast(hero: Node, _mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false

	var petrify_chance = get_petrify_chance(level)

	if not Global.hero_took_damage.is_connected(_on_hero_hit):
		Global.hero_took_damage.connect(_on_hero_hit.bind(petrify_chance, level))
	return true

static func _on_hero_hit(_amount: float, _is_magic: bool, attacker: Node, petrify_chance: float, level: int):
	if attacker == null:
		return
	if not is_instance_valid(attacker):
		return
	if not attacker.has_method("apply_debuff"):
		return
	if attacker.has_debuff("petrified"):
		return
	
	# 【属性系统】如果攻击者有 earth aura（土属性光环），石化概率减半
	# 土属性代表坚固/稳定，抵抗石化效果
	var final_chance = petrify_chance
	if attacker.get("elemental_aura") == "earth":
		final_chance *= 0.5  # earth aura 怪物石化概率减半
	
	if randf() < final_chance:
		var duration = get_petrify_duration(level)
		attacker.apply_debuff("petrified", duration, {}, "earth")
