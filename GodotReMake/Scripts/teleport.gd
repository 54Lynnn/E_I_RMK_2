extends Node2D
class_name TeleportHandler

static var skill_name := "teleport"
static var skill_type := "active"  # 技能类型: active, toggle, passive
static var base_cooldown := 20.0
static var base_mana_cost := 35.0

static func get_mana_cost(level: int) -> float:
	return max(base_mana_cost - (level - 1) * 2.0, 25.0)

static func get_cooldown(level: int) -> float:
	return max(base_cooldown - (level - 1) * 1.0, 15.0)

static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	var mana_cost = get_mana_cost(level)
	if not (Global.free_spells or Global.mana >= mana_cost):
		return false

	var teleport_pos = mouse_pos
	if not _is_valid_teleport_position(hero, teleport_pos):
		return false

	if not Global.free_spells:
		Global.mana -= mana_cost
		Global.mana_changed.emit(Global.mana, Global.max_mana)

	var handler = TeleportHandler.new()
	handler.hero_ref = hero
	handler.target_pos = teleport_pos
	handler.skill_cooldowns = skill_cooldowns
	handler.cooldown_value = get_cooldown(level)
	hero.get_parent().add_child(handler)
	handler.start_teleport()

	skill_cooldowns[skill_name] = get_cooldown(level)
	return true

static func _is_valid_teleport_position(hero: Node, pos: Vector2) -> bool:
	var margin = 32.0
	if pos.x < margin or pos.x > 2560.0 - margin or pos.y < margin or pos.y > 2560.0 - margin:
		return false
	var space_state = hero.get_viewport().get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = 1
	var results = space_state.intersect_shape(query)
	return results.is_empty()

var hero_ref: Node = null
var target_pos := Vector2.ZERO
var skill_cooldowns: Dictionary = {}
var cooldown_value := 0.0

func start_teleport():
	if hero_ref == null:
		queue_free()
		return

	_spawn_flash(hero_ref.global_position)

	hero_ref.set_process(false)
	hero_ref.set_physics_process(false)

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.25
	add_child(timer)
	timer.timeout.connect(_do_teleport)
	timer.start()

func _do_teleport():
	if not is_instance_valid(hero_ref):
		queue_free()
		return

	if _is_valid_teleport_position(hero_ref, target_pos):
		hero_ref.global_position = target_pos

	hero_ref.set_process(true)
	hero_ref.set_physics_process(true)

	_spawn_flash(hero_ref.global_position)
	queue_free()

func _spawn_flash(pos: Vector2):
	if not is_instance_valid(hero_ref):
		return
	var flash = Sprite2D.new()
	if ResourceLoader.exists("res://Art/Placeholder/Teleport.png"):
		flash.texture = load("res://Art/Placeholder/Teleport.png")
	flash.global_position = pos
	flash.modulate = Color(0.5, 0.3, 1.0, 0.8)
	hero_ref.get_parent().add_child(flash)
	var ftween = flash.create_tween()
	ftween.tween_property(flash, "modulate:a", 0.0, 0.25)
	ftween.tween_callback(flash.queue_free)
