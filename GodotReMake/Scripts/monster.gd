extends CharacterBody2D

@export var move_speed := 65.0
@export var health := 30.0
@export var max_health := 30.0
@export var damage := 5.0
@export var collision_damage := 2.0
@export var experience_reward := 30
@export var detection_range := 400.0
@export var attack_range := 40.0
@export var attack_cooldown := 2.0

enum State { IDLE, CHASE, ATTACK, HURT, DEATH }
var current_state := State.IDLE
var target: Node2D = null
var can_attack := true

@onready var sprite := $Sprite2D
@onready var health_bar := $HealthBar
@onready var state_timer := $StateTimer
@onready var attack_cooldown_timer := $AttackCooldown

func _ready():
	add_to_group("monsters")
	health_bar.max_value = max_health
	health_bar.value = health
	sprite.rotation = 0
	state_timer.wait_time = 1.0 + randf() * 2.0
	state_timer.timeout.connect(_on_state_timer_timeout)
	state_timer.start()
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)

func _physics_process(delta):
	if current_state == State.DEATH:
		return
	find_target()
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			if target:
				current_state = State.CHASE
		State.CHASE:
			if target:
				var dist = global_position.distance_to(target.global_position)
				if dist <= attack_range:
					current_state = State.ATTACK
				else:
					var dir = global_position.direction_to(target.global_position)
					velocity = dir * move_speed
					sprite.rotation = atan2(dir.y, dir.x)
			else:
				current_state = State.IDLE
		State.ATTACK:
			velocity = Vector2.ZERO
			if target:
				var dist = global_position.distance_to(target.global_position)
				if dist > attack_range * 1.5:
					current_state = State.CHASE
				elif can_attack:
					perform_attack()
			else:
				current_state = State.IDLE
	move_and_slide()

func find_target():
	var heroes = get_tree().get_nodes_in_group("hero")
	if heroes.size() > 0:
		var hero = heroes[0]
		var dist = global_position.distance_to(hero.global_position)
		if dist <= detection_range and hero.visible:
			target = hero
		else:
			target = null
	else:
		target = null

func perform_attack():
	if target and can_attack:
		can_attack = false
		attack_cooldown_timer.start(attack_cooldown)
		var dist = target.global_position.distance_to(global_position)
		if dist <= attack_range + 20.0:
			Global.take_damage(damage, false)

func _on_attack_cooldown_timeout():
	can_attack = true

func take_damage(amount: float, damage_element: String = "basic"):
	if current_state == State.DEATH:
		return
	
	# 根据伤害元素类型应用抗性（后续可扩展为完整的抗性系统）
	var resist := 0.0
	match damage_element:
		"earth":
			resist = 0.0  # 土系抗性
		"air":
			resist = 0.0  # 气系抗性
		"fire":
			resist = 0.0  # 火系抗性
		"water":
			resist = 0.0  # 水系抗性
		_:
			resist = 0.0  # basic或其他类型
	
	amount *= (1.0 - resist)
	
	health -= amount
	health_bar.value = health
	health_bar.visible = true
	var flash_tween = create_tween()
	sprite.modulate = Color(1, 0.3, 0.3)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		die()
	else:
		current_state = State.HURT
		state_timer.start(0.3)

func die():
	current_state = State.DEATH
	health_bar.visible = false
	set_collision_layer_value(1, false)
	Global.gain_experience(experience_reward)
	LootManager.try_drop(global_position, get_parent())
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _on_state_timer_timeout():
	if current_state == State.HURT:
		current_state = State.CHASE if target else State.IDLE
