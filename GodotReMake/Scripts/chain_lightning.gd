extends Node2D

static var skill_name := "chain_lightning"
static var base_cooldown := 1.0
static var base_mana_cost := 55.0
static var base_damage := 1000.0
static var damage_element := "air"

static func get_mana_cost(level: int) -> float:
	return 55.0 + (level - 1) * 2.0

static func get_damage(level: int) -> float:
	return 1000.0 + (level - 1) * 50.0

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
	var monsters = hero.get_tree().get_nodes_in_group("monsters")
	var alive = []
	for m in monsters:
		if is_instance_valid(m):
			alive.append(m)

	var bounce_count = 5
	var current_target = null
	var last_pos = mouse_pos

	for i in range(bounce_count):
		var closest = null
		var closest_dist = 400.0
		for m in alive:
			if not is_instance_valid(m):
				continue
			var dist = last_pos.distance_to(m.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = m

		if closest == null:
			break

		closest.take_damage(damage, damage_element)
		last_pos = closest.global_position
		alive.erase(closest)

		var bolt = Sprite2D.new()
		bolt.modulate = Color(1.0, 0.9, 0.3, 0.8)
		bolt.scale = Vector2(0.5, 0.5)
		bolt.global_position = last_pos
		hero.get_parent().add_child(bolt)
		var btween = bolt.create_tween()
		btween.tween_property(bolt, "modulate:a", 0.0, 0.2)
		btween.tween_callback(bolt.queue_free)

	skill_cooldowns[skill_name] = base_cooldown
	return true
