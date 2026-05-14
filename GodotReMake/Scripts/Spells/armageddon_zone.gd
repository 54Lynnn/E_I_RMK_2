extends Node2D

const MeteorSingleScene = preload("res://Scenes/MeteorSingle.tscn")

@export var damage := 250.0
@export var explosion_radius := 56.0
@export var damage_element := "fire"
@export var map_size := Vector2(1536, 1536)
@export var drop_interval := 0.2
@export var meteors_per_drop := 15
@export var duration := 2.0

var life_time := 0.0
var drop_timer := 0.0

func reset_for_pool():
	life_time = 0.0
	drop_timer = 0.0

func _process(delta):
	life_time += delta
	drop_timer += delta

	if drop_timer >= drop_interval:
		drop_timer = 0.0
		for i in range(meteors_per_drop):
			_spawn_meteor()

	if life_time >= duration:
		ObjectPool.return_to_pool(self)

func _spawn_meteor():
	var random_pos = Vector2(
		randf_range(0.0, map_size.x),
		randf_range(0.0, map_size.y)
	)

	var meteor = ObjectPool.get_object(MeteorSingleScene)
	meteor.name = "armageddon_proj"
	meteor.global_position = random_pos + Vector2(0, -400)
	meteor.target_position = random_pos
	meteor.damage = damage
	meteor.explosion_radius = explosion_radius
	meteor.damage_element = damage_element
	get_parent().add_child(meteor)
