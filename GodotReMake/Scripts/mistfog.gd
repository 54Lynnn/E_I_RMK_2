extends Area2D

static var skill_name := "mistfog"
static var skill_type := "active"  # 技能类型: active, toggle, passive
static var base_cooldown := 5.0
static var base_mana_cost := 25.0
static var base_duration := 20.0
static var base_slow_factor := 0.35

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + (level - 1) * 1.6

static func get_slow_factor(level: int) -> float:
	return min(base_slow_factor + (level - 1) * 0.07, 0.70)

static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	var mana_cost = get_mana_cost(level)

	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)

		var fog = preload("res://Scenes/MistFog.tscn").instantiate()
		fog.global_position = mouse_pos
		fog.slow_factor = get_slow_factor(level)
		hero.get_parent().add_child(fog)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

@export var slow_factor := 0.35
@export var radius := 150.0

var life_time := 0.0
var active_monsters := []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 地面效果技能层级：
	# Ground: 0, PickupItem: 3, 地面效果: 5, Hero/Monster: 10
	z_index = 5

	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = radius

	# 创建圆形边界线（开发调试用，显示实际作用范围）
	var boundary = Line2D.new()
	boundary.name = "Boundary"
	boundary.width = 2.0
	boundary.default_color = Color(0.3, 0.8, 1.0, 1.0)  # 天蓝色，不透明
	# 绘制圆形边界
	var points = []
	var segments = 64
	for i in range(segments + 1):
		var angle = float(i) / segments * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	boundary.points = points
	add_child(boundary)

	var fog_texture = _create_fog_texture()
	$Sprite2D.texture = fog_texture
	# 技能图标缩放：以圆形边界为参考
	var icon_size = radius * sqrt(2)
	$Sprite2D.scale = Vector2(icon_size / 128.0, icon_size / 128.0)  # fog_texture是128x128
	$Sprite2D.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _create_fog_texture() -> ImageTexture:
	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size * 0.5, size * 0.5)
	var max_dist = size * 0.5
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var alpha = 1.0 - smoothstep(0.4, 1.0, dist / max_dist)
			alpha *= 0.5
			image.set_pixel(x, y, Color(0.5, 0.5, 0.5, alpha))
	return ImageTexture.create_from_image(image)

func _process(delta):
	life_time += delta
	if life_time >= 20.0:
		for m in active_monsters:
			if is_instance_valid(m):
				m.remove_debuff("slowed")
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("monsters") and body.has_method("apply_debuff"):
		if body not in active_monsters:
			active_monsters.append(body)
		body.apply_debuff("slowed", 20.0, {"factor": slow_factor})

func _on_body_exited(body):
	if body in active_monsters:
		active_monsters.erase(body)
	if is_instance_valid(body) and body.has_method("remove_debuff"):
		body.remove_debuff("slowed")
