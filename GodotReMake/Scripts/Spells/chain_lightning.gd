extends Node2D

const LightningProjScene = preload("res://Scenes/ChainLightningProj.tscn")

static var skill_name := "chain_lightning"
static var skill_type := "active"
static var base_cooldown := 1.0
static var base_mana_cost := 55.0
static var base_damage := 1000.0
static var damage_element := "air"

static func get_mana_cost(level: int) -> float:
	return 55.0 + (level - 1) * 2.0

static func get_damage(level: int) -> float:
	return 1000.0 + (level - 1) * 50.0

static func get_cooldown(level: int) -> float:
	return max(1.0 - (level - 1) * 0.05, 0.5)

static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	var mana_cost = get_mana_cost(level)
	if not (Global.free_spells or Global.mana >= mana_cost):
		return false

	if not Global.free_spells:
		Global.mana -= mana_cost
		Global.mana_changed.emit(Global.mana, Global.max_mana)

	var damage = get_damage(level)
	var muzzle = hero.get_node("Sprite2D/Muzzle")
	var start_pos = muzzle.global_position
	var direction = hero.global_position.direction_to(mouse_pos)

	# 创建闪电投射物
	var lightning = ObjectPool.get_object(LightningProjScene)
	lightning.name = "chain_lightning_proj"
	lightning.global_position = start_pos
	lightning.direction = direction
	lightning.damage = damage
	lightning.max_bounces = 10
	lightning.bounce_range = 300.0
	hero.get_parent().add_child(lightning)

	skill_cooldowns[skill_name] = get_cooldown(level)
	return true
