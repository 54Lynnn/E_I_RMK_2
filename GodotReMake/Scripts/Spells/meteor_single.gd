extends Node2D

const ExplosionScene = preload("res://Scenes/Explosion.tscn")

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

func reset_for_pool():
	damage = 250.0
	explosion_radius = 56.0
	fall_speed = 600.0
	damage_element = "fire"
	target_position = Vector2.ZERO
	has_exploded = false

func _explode():
	if has_exploded:
		return
	has_exploded = true

	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if not is_instance_valid(m):
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= explosion_radius:
			if m.has_method("take_damage"):
				m.take_damage(damage, damage_element)

	var explosion = ObjectPool.get_object(ExplosionScene)
	explosion.global_position = global_position
	explosion.scale = Vector2(explosion_radius / 30.0, explosion_radius / 30.0)
	get_parent().add_child(explosion)

	await get_tree().create_timer(0.3).timeout
	ObjectPool.return_to_pool(self)
