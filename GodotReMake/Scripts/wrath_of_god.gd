extends Node2D

static var skill_name := "wrath_of_god"
static var base_cooldown := 30.0
static var base_mana_cost := 50.0
static var base_damage := 30.0
static var damage_element := "earth"

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 10.0

static func get_damage(level: int) -> float:
	return base_damage + level * 15.0

static func get_cooldown(level: int) -> float:
	return max(base_cooldown - level * 1.0, 10.0)

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

		var damage = get_damage(level)
		var monsters = hero.get_tree().get_nodes_in_group("monsters")
		for m in monsters:
			if is_instance_valid(m) and m.has_method("take_damage"):
				m.take_damage(damage, damage_element)

		var effect = Sprite2D.new()
		if ResourceLoader.exists("res://Art/Placeholder/WrathOfGod.png"):
			effect.texture = load("res://Art/Placeholder/WrathOfGod.png")
		effect.global_position = hero.global_position
		effect.modulate = Color(0.8, 0.6, 0.2, 0.9)
		effect.scale = Vector2(3, 3)
		hero.get_parent().add_child(effect)
		var etween = effect.create_tween()
		etween.tween_property(effect, "modulate:a", 0.0, 1.0)
		etween.tween_callback(effect.queue_free)

		skill_cooldowns[skill_name] = get_cooldown(level)
		return true
	return false
