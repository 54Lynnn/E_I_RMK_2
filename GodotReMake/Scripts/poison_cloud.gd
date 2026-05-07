extends Area2D

static var skill_name := "poison_cloud"
static var base_cooldown := 12.0
static var base_mana_cost := 25.0
static var base_damage := 8.0
static var damage_element := "water"
static var base_duration := 6.0

static func get_mana_cost(level: int) -> float:
	return base_mana_cost + level * 3.0

static func get_damage(level: int) -> float:
	return base_damage + level * 3.0

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

		var cloud = preload("res://Scenes/PoisonCloud.tscn").instantiate()
		cloud.global_position = mouse_pos
		cloud.damage = get_damage(level)
		cloud.duration = get_duration(level)
		cloud.radius = 80.0 + level * 4.0
		hero.get_parent().add_child(cloud)

		skill_cooldowns[skill_name] = base_cooldown
		return true
	return false

@export var damage := 8.0
@export var duration := 6.0
@export var radius := 80.0

var life_time := 0.0
var damage_interval := 1.0
var damage_timer := 0.0
var damaged_monsters := []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = radius
	scale = Vector2(radius / 40.0, radius / 40.0)

	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, duration)
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
