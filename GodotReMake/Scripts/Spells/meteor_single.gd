extends Node2D

@export var damage := 250.0
@export var explosion_radius := 56.0
@export var fall_speed := 600.0
@export var damage_element := "fire"

var target_position := Vector2.ZERO
var has_exploded := false

func _ready():
	var fall_duration = 300.0 / fall_speed
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, fall_duration)
	tween.tween_callback(_explode)

func _explode():
	if has_exploded:
		return
	has_exploded = true

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = explosion_radius
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 4
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body and body.is_in_group("monsters") and body.has_method("take_damage"):
			body.take_damage(damage, damage_element)

	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(explosion_radius / 30.0, explosion_radius / 30.0)
	get_parent().add_child(explosion)

	await get_tree().create_timer(0.3).timeout
	queue_free()
