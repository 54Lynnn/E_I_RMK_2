extends Control

var progress := 0.0

func _draw():
	if progress <= 0.0:
		return
	
	var center = size / 2
	var radius = min(size.x, size.y) / 2.0 - 1
	var color = Color(0.2, 0.2, 0.2, 0.75)
	
	var points := PackedVector2Array()
	points.append(center)
	
	var start_angle = -PI / 2
	var end_angle = start_angle + progress * 2 * PI
	var segments = 32
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = start_angle + t * (end_angle - start_angle)
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
	
	draw_polygon(points, [color])

func set_progress(p: float):
	progress = clamp(p, 0.0, 1.0)
	queue_redraw()
