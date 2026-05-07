extends Area2D

static var skill_name := "dark_ritual"
static var skill_type := "active"  # 技能类型: active, toggle, passive
static var base_cooldown := 5.5
static var base_mana_cost := 55.0
static var base_damage := 0.0
static var damage_element := "water"
static var base_delay := 2.0
static var base_duration := 5.0  # 视觉效果持续时间（比debuff长，确保所有debuff都能触发）

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 2.5

static func get_instant_kill_chance(level: int) -> float:
	return 0.30 + level * 0.08

static func get_delay(level: int) -> float:
	return max(base_delay - level * 0.1, 0.5)

static func get_duration(level: int) -> float:
	# 视觉效果持续时间：确保比debuff时间长，让所有进入的敌人都能被判定
	return base_duration + level * 0.5

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

		var ritual = preload("res://Scenes/DarkRitual.tscn").instantiate()
		ritual.name = "dark_ritual_zone"
		ritual.global_position = mouse_pos
		ritual.instant_kill_chance = get_instant_kill_chance(level)
		ritual.delay = get_delay(level)
		ritual.duration = get_duration(level)
		ritual.radius = 130.0
		hero.get_parent().add_child(ritual)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

@export var damage := 100.0
@export var delay := 2.0
@export var duration := 5.0  # 视觉效果持续时间
@export var radius := 60.0
@export var instant_kill_chance := 0.3

var affected_monsters := []

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
	var segments = 64  # 圆的分段数，越多越平滑
	for i in range(segments + 1):
		var angle = float(i) / segments * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	boundary.points = points
	add_child(boundary)

	# 技能图标缩放：以圆形边界为参考，图标在圆内显示
	# 图标是正方形，外切圆的直径 = 正方形边长 * sqrt(2)
	# 所以图标边长 = 直径 / sqrt(2) = 半径 * 2 / sqrt(2) = 半径 * sqrt(2)
	var icon_size = radius * sqrt(2)
	$Sprite2D.scale = Vector2(icon_size / 64.0, icon_size / 64.0)  # 假设图标原始大小为64x64
	# 初始透明度较低，作为地面效果
	$Sprite2D.modulate = Color(0.3, 0.1, 0.5, 0.35)

	var tween = create_tween()
	# 淡入到中等透明度（持续时间的20%）
	tween.tween_property($Sprite2D, "modulate:a", 0.5, duration * 0.2)
	# 边界线也淡入
	tween.parallel().tween_property(boundary, "modulate:a", 1.0, duration * 0.2)
	# 保持可见（持续时间的60%）
	tween.tween_interval(duration * 0.6)
	# 淡出（持续时间的20%）
	tween.tween_property($Sprite2D, "modulate:a", 0.0, duration * 0.2)
	tween.parallel().tween_property(boundary, "modulate:a", 0.0, duration * 0.2)
	tween.tween_callback(queue_free)

func _on_body_entered(body):
	if body.is_in_group("monsters") and body.has_method("apply_debuff"):
		if body not in affected_monsters:
			affected_monsters.append(body)
		# 施加 dark_ritual debuff，持续时间为 delay
		body.apply_debuff("dark_ritual", delay, {"chance": instant_kill_chance, "damage": damage})

func _on_body_exited(body):
	if body in affected_monsters:
		affected_monsters.erase(body)

func _explode():
	# debuff 结束时，由 monster.gd 的 _on_debuff_removed 处理秒杀判定
	# 这里只负责视觉效果
	var explosion = preload("res://Scenes/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
