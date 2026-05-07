extends Node2D

static var skill_name := "armageddon"
static var base_cooldown := 60.0
static var base_mana_cost := 80.0
static var base_damage := 40.0
static var damage_element := "fire"
static var hit_count := 5

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 10.0

static func get_damage(level: int) -> float:
	return base_damage + level * 15.0

static func get_hit_count(level: int) -> int:
	return hit_count + int(level / 2)

func _ready():
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

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
		var hits = get_hit_count(level)
		var monsters = hero.get_tree().get_nodes_in_group("monsters")
		var alive_monsters = []
		for m in monsters:
			if is_instance_valid(m):
				alive_monsters.append(m)

		for i in range(hits):
			if alive_monsters.is_empty():
				break
			var target = alive_monsters[randi() % alive_monsters.size()]
			if is_instance_valid(target):
				target.take_damage(damage, damage_element)
				var flash = Sprite2D.new()
				flash.global_position = target.global_position
				flash.texture = preload("res://Art/Placeholder/Armageddon.png") if ResourceLoader.exists("res://Art/Placeholder/Armageddon.png") else null
				flash.modulate = Color(1.0, 0.8, 0.0, 0.8)
				flash.scale = Vector2(1.5, 1.5)
				hero.get_parent().add_child(flash)
				var ftween = flash.create_tween()
				ftween.tween_property(flash, "modulate:a", 0.0, 0.3)
				ftween.tween_callback(flash.queue_free)
			alive_monsters.erase(target)

		var effect = preload("res://Scenes/Armageddon.tscn").instantiate()
		effect.global_position = hero.global_position
		hero.get_parent().add_child(effect)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false
