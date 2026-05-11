extends Area2D

@export var speed := 800.0
@export var damage := 1000.0
@export var damage_element := "air"
@export var max_bounces := 10
@export var bounce_range := 300.0

var direction := Vector2.RIGHT
var current_target = null
var is_moving := true
var bounce_count := 0
var hit_monsters := []

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if not is_moving:
		return

	if current_target != null and is_instance_valid(current_target):
		var target_pos = current_target.global_position
		var dist = global_position.distance_to(target_pos)
		if dist < 10.0:
			_reach_target()
		else:
			direction = global_position.direction_to(target_pos)
			position += direction * speed * delta
	else:
		position += direction * speed * delta

func _on_body_entered(body):
	if not is_moving:
		return
	if body.is_in_group("monsters"):
		if current_target == null:
			current_target = body
			_reach_target()
		elif body == current_target:
			_reach_target()

func _reach_target():
	is_moving = false

	if current_target != null and is_instance_valid(current_target):
		if current_target.has_method("take_damage"):
			current_target.take_damage(damage, damage_element)
		hit_monsters.append(current_target)
		bounce_count += 1

		_spawn_hit_effect(current_target.global_position)

	if bounce_count >= max_bounces:
		queue_free()
		return

	var next_target = _find_next_target()
	if next_target == null:
		queue_free()
		return

	if current_target != null and is_instance_valid(current_target):
		_spawn_chain_effect(current_target.global_position, next_target.global_position)
	else:
		_spawn_chain_effect(global_position, next_target.global_position)

	current_target = next_target
	is_moving = true

func _find_next_target() -> Node:
	var from_pos = global_position
	if current_target != null and is_instance_valid(current_target):
		from_pos = current_target.global_position

	var monsters = get_tree().get_nodes_in_group("monsters")
	var closest = null
	var closest_dist = bounce_range

	for m in monsters:
		if not is_instance_valid(m):
			continue
		if m in hit_monsters:
			continue
		var dist = from_pos.distance_to(m.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = m

	return closest

func _spawn_hit_effect(pos: Vector2):
	var bolt = Sprite2D.new()
	bolt.modulate = Color(1.0, 0.9, 0.3, 0.9)
	bolt.scale = Vector2(1.0, 1.0)
	bolt.global_position = pos
	get_parent().add_child(bolt)
	var btween = bolt.create_tween()
	btween.tween_property(bolt, "modulate:a", 0.0, 0.3)
	btween.tween_callback(bolt.queue_free)

func _spawn_chain_effect(from_pos: Vector2, to_pos: Vector2):
	var beam = Line2D.new()
	beam.add_point(from_pos)
	beam.add_point(to_pos)
	beam.default_color = Color(1.0, 0.9, 0.3, 0.9)
	beam.width = 5.0
	beam.antialiased = true
	get_parent().add_child(beam)
	var btween = beam.create_tween()
	btween.tween_property(beam, "default_color:a", 0.0, 0.3)
	btween.parallel().tween_property(beam, "width", 0.0, 0.3)
	btween.tween_callback(beam.queue_free)
