extends Area2D

static var skill_name := "holy_light"
static var base_cooldown := 8.0
static var base_mana_cost := 20.0
static var base_damage := 25.0
static var damage_element := "air"

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 3.0

static func get_damage(level: int) -> float:
	return base_damage + level * 10.0

static func get_beam_width(level: int) -> float:
	return 20.0 + level * 3.0

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

		var beam = preload("res://Scenes/HolyLight.tscn").instantiate()
		var muzzle = hero.get_node("Sprite2D/Muzzle")
		beam.global_position = muzzle.global_position
		beam.direction = hero.global_position.direction_to(mouse_pos)
		beam.damage = get_damage(level)
		beam.beam_width = get_beam_width(level)
		hero.get_parent().add_child(beam)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

@export var damage := 25.0
@export var beam_width := 20.0
@export var max_length := 600.0

var direction := Vector2.RIGHT
var hit_targets := []

func _ready():
	direction = direction.normalized()
	rotation = direction.angle()

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * max_length)
	query.collision_mask = 4
	var result = space_state.intersect_ray(query)

	var end_pos = result.get("position", global_position + direction * max_length) if result else global_position + direction * max_length
	var beam_length = global_position.distance_to(end_pos)

	$RayVisual.scale = Vector2(beam_length / 16.0, beam_width / 8.0)

	var hitbox = RectangleShape2D.new()
	hitbox.size = Vector2(beam_length, beam_width)
	$Hitbox.shape = hitbox
	$Hitbox.position = Vector2(beam_length / 2.0, 0)

	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if not is_instance_valid(m):
			continue
		var dist = global_position.distance_to(m.global_position)
		var angle_diff = abs(global_position.angle_to_point(m.global_position) - direction.angle())
		if dist <= beam_length and angle_diff < beam_width / dist:
			if m.has_method("take_damage"):
				m.take_damage(damage, damage_element)

	var tween = create_tween()
	tween.tween_property($RayVisual, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
