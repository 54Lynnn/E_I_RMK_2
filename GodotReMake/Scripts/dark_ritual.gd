extends Area2D

static var skill_name := "dark_ritual"
static var base_cooldown := 5.5
static var base_mana_cost := 55.0
static var damage_element := "water"
static var base_delay := 2.0
static var base_duration := 5.0

static func get_mana_cost(level: int) -> float:
	return 55.0 + (level - 1) * 2.5

static func get_instant_kill_chance(level: int) -> float:
	return min(0.30 + (level - 1) * 0.067, 0.90)

static func get_cooldown(level: int) -> float:
	return max(5.5 - (level - 1) * 0.5, 1.0)

static func get_duration(level: int) -> float:
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
		ritual.delay = base_delay
		ritual.duration = get_duration(level)
		ritual.radius = 130.0
		hero.get_parent().add_child(ritual)

		skill_cooldowns[skill_name] = get_cooldown(level)
		return true
	return false

@export var damage := 100.0
@export var delay := 2.0
@export var duration := 5.0
@export var radius := 60.0
@export var instant_kill_chance := 0.3

# 记录每个怪物的debuff累积进度
# key: 怪物节点, value: 已累积时间
var monster_debuff_progress := {}
var checked_monsters := []
var life_time := 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	z_index = 5

	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = radius

	var boundary = Line2D.new()
	boundary.name = "Boundary"
	boundary.width = 2.0
	boundary.default_color = Color(0.3, 0.8, 1.0, 1.0)
	var points = []
	var segments = 64
	for i in range(segments + 1):
		var angle = float(i) / segments * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	boundary.points = points
	add_child(boundary)

	var icon_size = radius * sqrt(2)
	$Sprite2D.scale = Vector2(icon_size / 64.0, icon_size / 64.0)
	$Sprite2D.modulate = Color(0.3, 0.1, 0.5, 0.35)

	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.5, duration * 0.2)
	tween.parallel().tween_property(boundary, "modulate:a", 1.0, duration * 0.2)
	tween.tween_interval(duration * 0.6)
	tween.tween_property($Sprite2D, "modulate:a", 0.0, duration * 0.2)
	tween.parallel().tween_property(boundary, "modulate:a", 0.0, duration * 0.2)
	tween.tween_callback(queue_free)

func _process(delta):
	life_time += delta

	# 更新范围内怪物的debuff累积进度
	for monster in monster_debuff_progress.keys():
		if not is_instance_valid(monster):
			monster_debuff_progress.erase(monster)
			continue

		if monster in checked_monsters:
			continue

		monster_debuff_progress[monster] += delta

		# debuff累积满，进行判定
		if monster_debuff_progress[monster] >= delay:
			checked_monsters.append(monster)
			if monster.has_method("take_damage"):
				if randf() < instant_kill_chance:
					monster.take_damage(99999.0, damage_element)
				# 判定失败则不造成伤害

func _on_body_entered(body):
	if body.is_in_group("monsters"):
		if body not in checked_monsters and not monster_debuff_progress.has(body):
			monster_debuff_progress[body] = 0.0

func _on_body_exited(body):
	if monster_debuff_progress.has(body):
		# 离开范围后，如果还没判定，清除累积进度
		if body not in checked_monsters:
			monster_debuff_progress.erase(body)
