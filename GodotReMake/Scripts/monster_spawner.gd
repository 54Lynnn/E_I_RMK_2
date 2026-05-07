extends Node2D

@export var spawn_interval := 2.0
@export var max_monsters := 6
@export var spawn_radius := 400.0

var active_monsters := 0
var time_since_spawn := 0.0

func _process(delta):
	time_since_spawn += delta
	if time_since_spawn >= spawn_interval and active_monsters < max_monsters:
		time_since_spawn = 0.0
		spawn_monster()

func spawn_monster():
	var monster_scenes = [
		preload("res://Scenes/Monster.tscn"),
		preload("res://Scenes/Zombie.tscn")
	]
	var scene = monster_scenes[randi() % monster_scenes.size()]
	var monster = scene.instantiate()
	var angle = randf() * TAU
	var hero = get_tree().get_first_node_in_group("hero")
	if not hero:
		return
	var spawn_pos = hero.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius
	monster.global_position = spawn_pos
	get_parent().add_child(monster)
	active_monsters += 1
	monster.tree_exited.connect(_on_monster_freed)

func _on_monster_freed():
	active_monsters -= 1
