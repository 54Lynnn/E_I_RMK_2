extends Node2D

@export var lifetime := 0.3

func _ready():
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(2, 2), lifetime)
	tween.parallel().tween_property($Sprite2D, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)
