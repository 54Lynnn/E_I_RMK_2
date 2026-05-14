extends Area2D

static var skill_name := "poison_cloud"
static var skill_type := "active"  # 技能类型: active, toggle, passive
static var base_cooldown := 5.0
static var base_mana_cost := 35.0
static var base_damage := 60.0
static var damage_element := "water"
static var base_duration := 10.0

static func get_mana_cost(level: int) -> float:
	return 35.0 + (level - 1) * 2.0  # LV1=35, LV10=53 (原版数据)

static func get_damage(level: int) -> float:
	return 50.0 + level * 10.0  # LV1=60, LV10=150 (原版数据)

static func get_duration(level: int) -> float:
	return 10.0  # 原版固定10秒

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

		var cloud = preload("res://Scenes/PoisonCloud.tscn").instantiate()
		cloud.name = "poison_cloud_zone"
		cloud.global_position = mouse_pos
		cloud.damage = get_damage(level) * 0.1
		cloud.duration = get_duration(level)
		cloud.radius = 110.0 * RelicManager.get_aoe_radius_multiplier()  # 原版固定110
		hero.get_parent().add_child(cloud)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

@export var damage := 8.0
@export var duration := 6.0
@export var radius := 80.0

var life_time := 0.0
var damage_interval := 0.1
var damage_timer := 0.0
var damaged_monsters := []

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

	# 技能图标缩放：以圆形边界为参考
	var icon_size = radius * sqrt(2)
	$Sprite2D.scale = Vector2(icon_size / 64.0, icon_size / 64.0)

	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, duration)
	tween.parallel().tween_property(boundary, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)

func _process(delta):
	life_time += delta
	damage_timer += delta

	if damage_timer >= damage_interval:
		damage_timer = 0.0
		var overlapping = get_overlapping_bodies()
		for body in overlapping:
			if body.is_in_group("monsters") and body.has_method("take_damage"):
				body.take_damage(damage, damage_element)

	if life_time >= duration:
		queue_free()

func _on_body_entered(_body):
	pass

func _on_body_exited(_body):
	pass
