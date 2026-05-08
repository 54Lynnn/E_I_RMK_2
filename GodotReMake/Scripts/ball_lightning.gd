extends Area2D

static var skill_name := "ball_lightning"
static var base_cooldown := 2.0
static var base_mana_cost := 45.0
static var base_damage := 200.0
static var damage_element := "air"

static func get_mana_cost(level: int) -> float:
	return 45.0 + (level - 1) * 2.0

static func get_damage(level: int) -> float:
	return 200.0 + (level - 1) * 10.0

static func get_cooldown(level: int) -> float:
	return max(2.0 - (level - 1) * 0.1, 1.1)

static func get_strike_count(_level: int) -> int:
	return 5

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

	var orbs = preload("res://Scenes/BallLightning.tscn").instantiate()
	orbs.name = "ball_lightning_proj"
	orbs.global_position = hero.global_position
	orbs.damage = get_damage(level)
	orbs.strikes = get_strike_count(level)
	hero.get_parent().add_child(orbs)

	skill_cooldowns[skill_name] = get_cooldown(level)
	return true

@export var damage := 200.0
@export var strikes := 5
@export var radius := 80.0
var targets_hit := 0

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 2.0)
	tween.tween_callback(queue_free)

func _on_body_entered(body):
	if body.is_in_group("monsters") and body.has_method("take_damage"):
		body.take_damage(damage, damage_element)
		targets_hit += 1

func _on_area_entered(area):
	if area.is_in_group("monsters") and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage, damage_element)
		targets_hit += 1
