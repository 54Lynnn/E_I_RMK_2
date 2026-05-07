extends Camera2D

@export var follow_speed := 5.0

var target: Node2D = null

func _ready():
	make_current()
	zoom = Vector2(0.5, 0.5)  # 视野翻倍

func _process(delta):
	if not target:
		target = get_tree().get_first_node_in_group("hero")
	if target and target.visible:
		global_position = global_position.lerp(target.global_position, follow_speed * delta)
