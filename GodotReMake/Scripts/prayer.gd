extends Node2D

static var skill_name := "prayer"
static var base_cooldown := 20.0
static var base_duration := 10.0
static var base_health_cost_percent := 0.65

static func get_health_cost_percent(level: int) -> float:
	return max(0.65 - (level - 1) * 0.05, 0.20)

static func get_mana_restore_percent(level: int) -> float:
	return 0.50 + (level - 1) * 0.05

static func get_cooldown(level: int) -> float:
	return 20.0 + (level - 1) * 1.0

var hero: Node = null
var level: int = 0
var is_active: bool = false

@onready var bubble_timer: Timer = $BubbleTimer
@onready var duration_timer: Timer = $DurationTimer

static func cast(hero_node: Node, _mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false

	var health_cost = Global.max_health * get_health_cost_percent(level)
	if Global.health <= health_cost:
		return false

	Global.health -= health_cost
	Global.health_changed.emit(Global.health, Global.max_health)

	var prayer_instance = preload("res://Scenes/Prayer.tscn").instantiate()
	prayer_instance.hero = hero_node
	prayer_instance.level = level
	hero_node.add_child(prayer_instance)
	prayer_instance.start()

	skill_cooldowns[skill_name] = get_cooldown(level)
	return true

func start():
	is_active = true
	bubble_timer.wait_time = 0.25
	bubble_timer.timeout.connect(_on_bubble_timer_timeout)
	bubble_timer.start()
	duration_timer.wait_time = base_duration
	duration_timer.timeout.connect(_on_duration_timer_timeout)
	duration_timer.start()
	_spawn_bubble()
	_start_periodic_effects()

func _start_periodic_effects():
	var mana_restore_percent = get_mana_restore_percent(level)
	var effect_timer = Timer.new()
	effect_timer.wait_time = 1.0
	effect_timer.one_shot = false
	add_child(effect_timer)
	effect_timer.timeout.connect(func():
		if not is_active or hero == null:
			effect_timer.stop()
			effect_timer.queue_free()
			return
		var mana_restore = Global.max_mana * mana_restore_percent / base_duration
		Global.mana = min(Global.mana + mana_restore, Global.max_mana)
		Global.mana_changed.emit(Global.mana, Global.max_mana)
	)
	effect_timer.start()
	duration_timer.timeout.connect(func():
		effect_timer.stop()
		effect_timer.queue_free()
	)

func _on_bubble_timer_timeout():
	if is_active:
		_spawn_bubble()

func _spawn_bubble():
	if hero == null:
		return
	var bubble = Sprite2D.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center = Vector2(16, 16)
	for x in range(32):
		for y in range(32):
			var dist = Vector2(x, y).distance_to(center)
			if dist < 12:
				var alpha = 1.0 - (dist / 12.0)
				image.set_pixel(x, y, Color(0.3, 0.6, 1.0, alpha * 0.7))
	var texture = ImageTexture.create_from_image(image)
	bubble.texture = texture
	var random_offset = Vector2(randf_range(-20, 20), randf_range(5, 20))
	bubble.position = random_offset
	bubble.z_index = 10
	add_child(bubble)
	var tween = create_tween()
	tween.parallel().tween_property(bubble, "position:y", bubble.position.y - 30, 0.5)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func():
		if is_instance_valid(bubble):
			bubble.queue_free()
	)

func _on_duration_timer_timeout():
	is_active = false
	bubble_timer.stop()
	for child in get_children():
		if child is Sprite2D and is_instance_valid(child) and child != bubble_timer and child != duration_timer:
			child.queue_free()
	await get_tree().create_timer(1.0).timeout
	queue_free()
