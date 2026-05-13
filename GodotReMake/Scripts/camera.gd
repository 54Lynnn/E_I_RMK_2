extends Camera2D

@export var follow_speed := 5.0
@export var map_size := Vector2(1536, 1536)
@export var shake_intensity := 0.0
@export var viewport_padding := 100.0

var target: Node2D = null
var base_position := Vector2.ZERO

func _ready():
	make_current()
	zoom = Vector2(1.0, 1.0)

func _process(delta):
	if not target:
		target = get_tree().get_first_node_in_group("hero")
	if target and target.visible:
		var target_pos = target.global_position
		
		var viewport_size = get_viewport().get_visible_rect().size
		var half_w = viewport_size.x * 0.5 / zoom.x
		var half_h = viewport_size.y * 0.5 / zoom.y
		
		var min_x = half_w + viewport_padding
		var max_x = map_size.x - half_w - viewport_padding
		var min_y = half_h + viewport_padding
		var max_y = map_size.y - half_h - viewport_padding
		
		if min_x < max_x:
			target_pos.x = clamp(target_pos.x, min_x, max_x)
		else:
			target_pos.x = map_size.x * 0.5
		
		if min_y < max_y:
			target_pos.y = clamp(target_pos.y, min_y, max_y)
		else:
			target_pos.y = map_size.y * 0.5
		
		base_position = base_position.lerp(target_pos, follow_speed * delta)
		
		if shake_intensity > 0.0:
			var offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			global_position = base_position + offset
			shake_intensity = max(0.0, shake_intensity - delta * 30.0)
			if shake_intensity <= 0.0:
				global_position = base_position
		else:
			global_position = base_position

func shake(intensity: float = 3.0):
	shake_intensity = intensity
