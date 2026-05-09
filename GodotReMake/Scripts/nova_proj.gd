extends Area2D

@export var speed := 300.0
@export var damage := 200.0
@export var explosion_radius := 100.0
@export var freeze_duration := 1.0
@export var damage_element := "water"

var direction := Vector2.RIGHT
var has_exploded := false

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if has_exploded:
		return
	position += direction * speed * delta

func _on_body_entered(body):
	if has_exploded:
		return
	if body.is_in_group("monsters"):
		_explode()

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
			if m.has_method("apply_debuff"):
				m.apply_debuff("frozen", freeze_duration)

	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(explosion_radius / 30.0, explosion_radius / 30.0)
	get_parent().add_child(explosion)

	queue_free()
