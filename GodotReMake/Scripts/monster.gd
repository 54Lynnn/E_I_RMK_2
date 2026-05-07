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
var original_move_speed := 65.0

@onready var sprite := $Sprite2D
@onready var health_bar := $HealthBar
@onready var state_timer := $StateTimer
@onready var attack_cooldown_timer := $AttackCooldown

var debuffs := {}

func _ready():
	add_to_group("monsters")
	original_move_speed = move_speed
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
	_process_debuffs(delta)
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

func apply_debuff(name: String, duration: float, params: Dictionary = {}):
	if current_state == State.DEATH:
		return
	if debuffs.has(name):
		debuffs[name].remaining = duration
		debuffs[name].params = params
	else:
		debuffs[name] = {"remaining": duration, "duration": duration, "params": params}
	_on_debuff_applied(name)

func remove_debuff(name: String):
	if not debuffs.has(name):
		return
	debuffs.erase(name)
	if current_state == State.DEATH:
		return
	_on_debuff_removed(name)

func has_debuff(name: String) -> bool:
	return debuffs.has(name)

func _process_debuffs(delta):
	var expired = []
	for name in debuffs:
		debuffs[name].remaining -= delta
		if debuffs[name].remaining <= 0:
			expired.append(name)
	for name in expired:
		remove_debuff(name)

func _on_debuff_applied(name: String):
	match name:
		"frozen":
			move_speed = 0.0
			can_attack = false
			sprite.modulate = Color(0.5, 0.8, 1.0)
		"slowed":
			var factor = debuffs[name].params.get("factor", 0.5)
			move_speed = original_move_speed * clamp(1.0 - factor, 0.0, 1.0)
		"petrified":
			move_speed = 0.0
			can_attack = false
			sprite.modulate = Color(0.3, 0.3, 0.3)

func _on_debuff_removed(name: String):
	if current_state == State.DEATH:
		return
	match name:
		"frozen":
			move_speed = original_move_speed
			can_attack = true
			sprite.modulate = Color.WHITE
		"slowed":
			_recalculate_speed()
		"petrified":
			die()

func _recalculate_speed():
	move_speed = original_move_speed
	for name in debuffs:
		var d = debuffs[name]
		match name:
			"slowed":
				var factor = d.params.get("factor", 0.5)
				move_speed *= clamp(1.0 - factor, 0.0, 1.0)

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
			Global.take_damage(damage, false, self)

func _on_attack_cooldown_timeout():
	can_attack = true

func take_damage(amount: float, damage_element: String = "basic"):
	if current_state == State.DEATH:
		return
	var resist := 0.0
	match damage_element:
		"earth":
			resist = 0.0
		"air":
			resist = 0.0
		"fire":
			resist = 0.0
		"water":
			resist = 0.0
		_:
			resist = 0.0
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
	if current_state == State.DEATH:
		return
	current_state = State.DEATH
	debuffs.clear()
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
