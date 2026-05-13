extends Node2D

@export var lifetime := 0.3

static var _circle_tex: ImageTexture = null

func _ready():
	if _circle_tex == null:
		_circle_tex = _create_circle_texture(16, Color(1.0, 0.85, 0.1))
	$Sprite2D.texture = _circle_tex
	$Sprite2D.scale = Vector2(0.3, 0.3)
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(0.7, 0.7), lifetime)
	tween.parallel().tween_property($Sprite2D, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)

static func _create_circle_texture(radius: int, color: Color = Color.WHITE) -> ImageTexture:
	var diameter = radius * 2
	var image = Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center = Vector2(radius, radius)
	var radius_sq = radius * radius
	for y in range(diameter):
		for x in range(diameter):
			if Vector2(x, y).distance_squared_to(center) <= radius_sq:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
