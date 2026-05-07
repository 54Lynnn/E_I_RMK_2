extends CharacterBody2D

# ============================================
# Hero.gd - 玩家英雄控制器
# ============================================
# 这个文件控制玩家角色的所有行为，包括：
# 1. 移动控制（WASD）
# 2. 技能施放（调用各技能脚本的 cast 方法）
# 3. 鼠标瞄准（角色朝向鼠标）
# 4. 碰撞检测（与怪物碰撞）
# 5. 冷却时间管理（维护 skill_cooldowns 字典）
#
# 节点结构（在Hero.tscn中定义）：
# - Sprite2D: 角色精灵图
#   - Muzzle: 发射口（技能从这里发射）
# - CastCooldown: 计时器（控制技能冷却）
# - HealthBar: 头顶血条
# - ManaBar: 头顶蓝条
# - LevelLabel: 头顶等级标签
#
# 技能施放流程：
# 1. 检测按键输入 -> _unhandled_input()
# 2. 调用对应技能的 SkillScript.cast(self, mouse_pos, skill_cooldowns)
# 3. 技能脚本内部处理：检查等级、冷却、法力、创建效果、设置冷却
# ============================================

# 导入已重构的技能脚本
const MagicMissile = preload("res://Scripts/magic_missile.gd")
const Fireball = preload("res://Scripts/fireball.gd")
const FreezingSpear = preload("res://Scripts/freezing_spear.gd")
const Prayer = preload("res://Scripts/prayer.gd")
const Heal = preload("res://Scripts/heal.gd")

# 基础移动速度（像素/秒）
# 实际速度 = BASE_MOVE_SPEED + 敏捷×0.5 + 耐力×0.35
const BASE_MOVE_SPEED := 65.0

# 加速度和摩擦力（用于平滑移动）
# 值越大，角色启动和停止越快
@export var acceleration := 1200.0
@export var friction := 800.0

# @onready 表示在节点_ready()时自动获取这些子节点
@onready var sprite := $Sprite2D          # 角色精灵图
@onready var muzzle := $Sprite2D/Muzzle   # 技能发射位置
@onready var cast_cooldown := $CastCooldown  # 技能冷却计时器

# 变量声明
var mouse_pos := Vector2.ZERO   # 鼠标在世界中的位置

# 技能独立冷却系统（每个技能有自己的冷却状态）
var skill_cooldowns := {
	"magic_missile": 0.0,
	"fireball": 0.0,
	"freezing_spear": 0.0,
	"prayer": 0.0,
	"teleport": 0.0,
	"mistfog": 0.0,
	"wrath_of_god": 0.0,
	"telekinesis": 0.0,
	"sacrifice": 0.0,
	"holy_light": 0.0,
	"ball_lightning": 0.0,
	"chain_lightning": 0.0,
	"heal": 0.0,
	"fire_walk": 0.0,
	"meteor": 0.0,
	"armageddon": 0.0,
	"poison_cloud": 0.0,
	"fortuna": 0.0,
	"dark_ritual": 0.0,
	"nova": 0.0,
}

# 技能状态标记
var prayer_active := false      # 祈祷技能是否激活
var teleport_casting := false   # 传送是否正在施法中

# 预加载投射物场景（已重构的技能不再需要，保留给未重构的技能）
# const FIREBALL_SCENE = preload("res://Scenes/Fireball.tscn")
# const MAGIC_MISSILE_SCENE = preload("res://Scenes/MagicMissile.tscn")
# const FREEZING_SPEAR_SCENE = preload("res://Scenes/FreezingSpear.tscn")

# ============================================
# 生命周期函数
# ============================================

func _ready():
	# 初始化：连接信号和设置初始状态
	
	# 连接全局信号（当数据变化时更新显示）
	Global.health_changed.connect(_on_health_changed)
	Global.mana_changed.connect(_on_mana_changed)
	Global.level_changed.connect(_on_level_changed)
	Global.hero_died.connect(_on_died)
	
	# 应用属性计算（根据力量/智力计算最大生命/法力）
	Global.apply_strength()
	Global.apply_intelligence()
	
	# 设置初始生命和法力为满值
	Global.health = Global.max_health
	Global.mana = Global.max_mana

func _process(delta):
	# 每帧执行：更新鼠标位置和角色朝向
	
	# 获取鼠标在世界坐标系中的位置
	mouse_pos = get_global_mouse_position()
	
	# 让角色朝向鼠标方向
	# angle_to_point计算从角色到鼠标的角度（弧度）
	sprite.rotation = global_position.angle_to_point(mouse_pos)
	
	# 更新头顶的HUD显示
	update_hud()
	
	# 更新技能冷却
	for skill in skill_cooldowns.keys():
		if skill_cooldowns[skill] > 0:
			skill_cooldowns[skill] -= delta
			if skill_cooldowns[skill] < 0:
				skill_cooldowns[skill] = 0
	
	# 长按持续施法（每个技能独立冷却）
	if Input.is_action_pressed("spell_magic_missile"):
		cast_magic_missile()
	if Input.is_action_pressed("spell_fireball"):
		cast_fireball()
	if Input.is_action_pressed("spell_freezing_spear"):
		cast_freezing_spear()
	if Input.is_action_pressed("spell_prayer"):
		cast_prayer()
	if Input.is_action_pressed("spell_heal"):
		cast_heal()

func get_move_speed() -> float:
	# 计算实际移动速度
	# 受基础速度、敏捷、耐力和全局速度倍率影响
	return BASE_MOVE_SPEED + Global.hero_dexterity * 0.5 + Global.hero_stamina * 0.35

func _physics_process(delta):
	# 物理帧执行：处理移动和碰撞
	
	# 获取输入方向（WASD）
	# 返回Vector2，例如按W返回(0, -1)
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 计算目标速度 = 方向 × 移动速度 × 全局速度倍率（药水等）
	var target_velocity = input_dir * get_move_speed() * Global.speed_multiplier
	
	# 平滑过渡到目标速度（加速度效果）
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	
	# 执行移动并处理碰撞
	move_and_slide()
	
	# 检测与怪物的碰撞（仅用于石化附魔检查，不再造成伤害）
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		if col.get_collider().is_in_group("monsters"):
			var monster = col.get_collider()
			# 检查石化附魔（被动技能）
			_check_stone_enchanted(monster)

func _unhandled_input(event):
	if event.is_action_pressed("spell_magic_missile"):
		cast_magic_missile()
	if event.is_action_pressed("spell_fireball"):
		cast_fireball()
	if event.is_action_pressed("spell_freezing_spear"):
		cast_freezing_spear()
	if event.is_action_pressed("spell_prayer"):
		cast_prayer()
	if event.is_action_pressed("spell_heal"):
		cast_heal()

func cast_magic_missile():
	MagicMissile.cast(self, mouse_pos, skill_cooldowns)

func cast_fireball():
	Fireball.cast(self, mouse_pos, skill_cooldowns)

func cast_freezing_spear():
	FreezingSpear.cast(self, mouse_pos, skill_cooldowns)

func cast_prayer():
	Prayer.cast(self, mouse_pos, skill_cooldowns)

func cast_heal():
	Heal.cast(self, mouse_pos, skill_cooldowns)

func cast_teleport():
	var level = Global.skill_levels.get("teleport", 0)
	if level <= 0:
		return
	if skill_cooldowns["teleport"] > 0:
		return
	var mana_cost = 35.0 - (level - 1) * 2.0
	var cd = max(20.0 - (level - 1) * 1.0, 2.0)
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		teleport_casting = true
		skill_cooldowns["teleport"] = cd
		await get_tree().create_timer(0.2).timeout
		if teleport_casting:
			global_position = mouse_pos
			teleport_casting = false

func cast_mistfog():
	var level = Global.skill_levels.get("mistfog", 0)
	if level <= 0:
		return
	if skill_cooldowns["mistfog"] > 0:
		return
	var mana_cost = 25.0 - (level - 1) * 1.0
	var cd = max(5.0 - (level - 1) * 0.2, 1.0)
	var duration = 20.0 + (level - 1) * 1.0
	var slow_amount = 0.35 + (level - 1) * 0.05
	var radius = 150.0 + (level - 1) * 10.0
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["mistfog"] = cd
		_create_mistfog(mouse_pos, duration, slow_amount, radius)

func _create_mistfog(pos: Vector2, duration: float, slow: float, radius: float):
	var fog = Area2D.new()
	fog.global_position = pos
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = radius
	fog.add_child(collision)
	get_parent().add_child(fog)
	
	var timer = 0.0
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(fog.queue_free)
	
	var process_tween = create_tween()
	process_tween.set_loops(int(duration * 10))
	process_tween.tween_callback(func():
		if is_instance_valid(fog):
			for body in fog.get_overlapping_bodies():
				if body.is_in_group("monsters"):
					body.speed_multiplier = 1.0 - slow
	)
	process_tween.tween_interval(0.1)

func cast_wrath_of_god():
	var level = Global.skill_levels.get("wrath_of_god", 0)
	if level <= 0:
		return
	if skill_cooldowns["wrath_of_god"] > 0:
		return
	var mana_cost = 55.0 - (level - 1) * 2.0
	var cd = max(2.0 - (level - 1) * 0.1, 0.5)
	var damage = 200.0 + (level - 1) * 30.0
	var radius = 130.0 + (level - 1) * 10.0
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["wrath_of_god"] = cd
		_spawn_hammers(damage, radius)

func _spawn_hammers(damage: float, radius: float):
	for i in range(10):
		var angle = (TAU / 10.0) * i
		var hammer = Area2D.new()
		hammer.global_position = global_position
		var collision = CollisionShape2D.new()
		collision.shape = CircleShape2D.new()
		collision.shape.radius = 8.0
		hammer.add_child(collision)
		get_parent().add_child(hammer)
		
		var direction = Vector2(cos(angle), sin(angle))
		var tween = create_tween()
		tween.tween_property(hammer, "global_position", global_position + direction * radius, 0.5)
		tween.tween_callback(func():
			if is_instance_valid(hammer):
				for body in hammer.get_overlapping_bodies():
					if body.is_in_group("monsters"):
						body.take_damage(damage * Global.damage_multiplier, true)
				hammer.queue_free()
		)

func _check_stone_enchanted(monster):
	var level = Global.skill_levels.get("stone_enchanted", 0)
	if level <= 0:
		return
	var chance = 0.30 + (level - 1) * 0.05
	if randf() < chance:
		_petrify_monster(monster)

func _petrify_monster(monster):
	if not is_instance_valid(monster):
		return
	# 保存原始速度
	var original_speed = monster.move_speed if "move_speed" in monster else 65.0
	monster.move_speed = 0.0
	monster.can_attack = false
	if monster.has_node("Sprite2D"):
		monster.get_node("Sprite2D").modulate = Color(0.5, 0.3, 0.1)
	
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(monster):
		if monster.has_node("Sprite2D"):
			var sprite = monster.get_node("Sprite2D")
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
			tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
			tween.tween_callback(monster.queue_free)
		else:
			monster.queue_free()

func cast_telekinesis():
	var level = Global.skill_levels.get("telekinesis", 0)
	if level <= 0:
		return
	if skill_cooldowns["telekinesis"] > 0:
		return
	var pickup_time = max(1.0 - (level - 1) * 0.1, 0.1)
	var items = get_tree().get_nodes_in_group("pickup_items")
	var closest = null
	var closest_dist = 999999.0
	for item in items:
		var dist = global_position.distance_to(item.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = item
	if closest and closest_dist < 200.0:
		skill_cooldowns["telekinesis"] = pickup_time
		await get_tree().create_timer(pickup_time).timeout
		if is_instance_valid(closest):
			closest._on_body_entered(self)

func cast_sacrifice():
	var level = Global.skill_levels.get("sacrifice", 0)
	if level <= 0:
		return
	if skill_cooldowns["sacrifice"] > 0:
		return
	var health_cost = Global.max_health * (0.55 - (level - 1) * 0.02)
	var cd = max(3.0 - (level - 1) * 0.1, 0.5)
	if Global.free_spells or Global.health > health_cost:
		if not Global.free_spells:
			Global.health -= health_cost
			Global.health_changed.emit(Global.health, Global.max_health)
		skill_cooldowns["sacrifice"] = cd
		var monsters = get_tree().get_nodes_in_group("monsters")
		var closest = null
		var closest_dist = 999999.0
		for m in monsters:
			var dist = m.global_position.distance_to(mouse_pos)
			if dist < closest_dist:
				closest_dist = dist
				closest = m
		if closest and closest_dist < 100.0:
			_spawn_sacrifice_sword(closest)

func _spawn_sacrifice_sword(monster):
	if not is_instance_valid(monster):
		return
	var sword = Sprite2D.new()
	sword.texture = load("res://Art/Placeholder/Sacrifice.png")
	sword.global_position = monster.global_position + Vector2(0, -30)
	get_parent().add_child(sword)
	
	var tween = create_tween()
	tween.tween_property(sword, "global_position", monster.global_position, 1.0)
	tween.tween_callback(func():
		if is_instance_valid(monster):
			monster.take_damage(monster.health * 2.0, true)
		if is_instance_valid(sword):
			sword.queue_free()
	)

func cast_holy_light():
	var level = Global.skill_levels.get("holy_light", 0)
	if level <= 0:
		return
	if skill_cooldowns["holy_light"] > 0:
		return
	var mana_cost = max(35.0 - (level - 1) * 1.0, 10.0)
	var cd = 1.0
	var damage = 120.0 + (level - 1) * 30.0
	var ray_count = 3 + (level - 1)
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["holy_light"] = cd
		var base_angle = global_position.angle_to_point(mouse_pos)
		var spread = deg_to_rad(45.0)
		var start_angle = base_angle - spread / 2.0
		for i in range(ray_count):
			var angle = start_angle + (spread / max(ray_count - 1, 1)) * i
			_spawn_holy_ray(angle, damage)

func _spawn_holy_ray(angle: float, damage: float):
	var ray = RayCast2D.new()
	ray.global_position = global_position
	ray.target_position = Vector2(cos(angle), sin(angle)) * 300.0
	ray.collision_mask = 1 << 2
	get_parent().add_child(ray)
	
	var laser = Line2D.new()
	laser.add_point(global_position)
	laser.add_point(global_position + Vector2(cos(angle), sin(angle)) * 300.0)
	laser.default_color = Color(1.0, 1.0, 0.8, 1.0)
	laser.width = 3.0
	laser.z_index = 10
	get_parent().add_child(laser)
	
	var tween = create_tween()
	tween.tween_property(laser, "default_color:a", 0.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(laser):
			laser.queue_free()
		if is_instance_valid(ray):
			ray.queue_free()
	)
	
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(ray):
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider and collider.is_in_group("monsters"):
				collider.take_damage(damage * Global.damage_multiplier, true)

func cast_ball_lightning():
	var level = Global.skill_levels.get("ball_lightning", 0)
	if level <= 0:
		return
	if skill_cooldowns["ball_lightning"] > 0:
		return
	var mana_cost = max(45.0 - (level - 1) * 2.0, 10.0)
	var cd = max(2.0 - (level - 1) * 0.1, 0.5)
	var damage = 200.0 + (level - 1) * 20.0
	var max_hits = 5 + (level - 1)
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["ball_lightning"] = cd
		_spawn_ball_lightning(damage, max_hits)

func _spawn_ball_lightning(damage: float, max_hits: int):
	var ball = Area2D.new()
	ball.global_position = global_position
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 12.0
	ball.add_child(collision)
	get_parent().add_child(ball)
	
	var hits = 0
	var tween = create_tween()
	tween.set_loops(max_hits)
	tween.tween_callback(func():
		if not is_instance_valid(ball):
			return
		var monsters = get_tree().get_nodes_in_group("monsters")
		var closest = null
		var closest_dist = 999999.0
		for m in monsters:
			var dist = ball.global_position.distance_to(m.global_position)
			if dist < closest_dist and dist < 200.0:
				closest_dist = dist
				closest = m
		if closest:
			ball.global_position = closest.global_position
			closest.take_damage(damage * Global.damage_multiplier, true)
			hits += 1
			if hits >= max_hits:
				ball.queue_free()
	)
	tween.tween_interval(0.5)
	tween.finished.connect(func():
		if is_instance_valid(ball):
			ball.queue_free()
	)

func cast_chain_lightning():
	var level = Global.skill_levels.get("chain_lightning", 0)
	if level <= 0:
		return
	if skill_cooldowns["chain_lightning"] > 0:
		return
	var mana_cost = max(55.0 - (level - 1) * 2.0, 15.0)
	var cd = max(1.0 - (level - 1) * 0.05, 0.3)
	var damage = 1000.0 + (level - 1) * 100.0
	var bounces = 3 + int((level - 1) / 2)
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["chain_lightning"] = cd
		_spawn_chain_lightning(damage, bounces)

func _spawn_chain_lightning(damage: float, bounces: int):
	var direction = global_position.direction_to(mouse_pos)
	var lightning = Area2D.new()
	lightning.global_position = global_position
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 8.0
	lightning.add_child(collision)
	get_parent().add_child(lightning)
	
	var tween = create_tween()
	tween.tween_property(lightning, "global_position", global_position + direction * 400.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(lightning):
			lightning.queue_free()
	)
	
	var hit_monsters = []
	var check_timer = 0.0
	while check_timer < 0.3:
		await get_tree().create_timer(0.05).timeout
		check_timer += 0.05
		if not is_instance_valid(lightning):
			return
		for body in lightning.get_overlapping_bodies():
			if body.is_in_group("monsters") and body not in hit_monsters:
				hit_monsters.append(body)
				body.take_damage(damage * Global.damage_multiplier, "air")
				_bounce_lightning(body, damage, bounces - 1, hit_monsters)
				return

func _bounce_lightning(from_monster, damage: float, remaining_bounces: int, hit_monsters: Array):
	if remaining_bounces <= 0 or not is_instance_valid(from_monster):
		return
	
	await get_tree().create_timer(0.1).timeout
	if not is_instance_valid(from_monster):
		return
	
	var monsters = get_tree().get_nodes_in_group("monsters")
	var closest = null
	var closest_dist = 999999.0
	for m in monsters:
		if m in hit_monsters:
			continue
		var dist = from_monster.global_position.distance_to(m.global_position)
		if dist < closest_dist and dist < 200.0:
			closest_dist = dist
			closest = m
	
	if closest:
		var laser = Line2D.new()
		laser.add_point(from_monster.global_position)
		laser.add_point(closest.global_position)
		laser.default_color = Color(0.8, 0.9, 1.0, 1.0)
		laser.width = 4.0
		laser.z_index = 10
		get_parent().add_child(laser)
		
		var tween = create_tween()
		tween.tween_property(laser, "default_color:a", 0.0, 0.2)
		tween.tween_callback(laser.queue_free)
		
		closest.take_damage(damage * Global.damage_multiplier, "air")
		hit_monsters.append(closest)
		_bounce_lightning(closest, damage, remaining_bounces - 1, hit_monsters)



func cast_fire_walk():
	var level = Global.skill_levels.get("fire_walk", 0)
	if level <= 0:
		return
	if skill_cooldowns["fire_walk"] > 0:
		return
	var damage_per_second = 30.0 + (level - 1) * 5.0
	skill_cooldowns["fire_walk"] = 5.0
	_spawn_fire_trail(damage_per_second)

func _spawn_fire_trail(damage_per_second: float):
	var trail = Area2D.new()
	trail.global_position = global_position
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 20.0
	trail.add_child(collision)
	get_parent().add_child(trail)
	
	var tween = create_tween()
	tween.tween_interval(5.0)
	tween.tween_callback(trail.queue_free)
	
	var damage_tween = create_tween()
	damage_tween.set_loops(50)
	damage_tween.tween_callback(func():
		if is_instance_valid(trail):
			for body in trail.get_overlapping_bodies():
				if body.is_in_group("monsters"):
					body.take_damage(damage_per_second * 0.1 * Global.damage_multiplier, true)
	)
	damage_tween.tween_interval(0.1)

func cast_meteor():
	var level = Global.skill_levels.get("meteor", 0)
	if level <= 0:
		return
	if skill_cooldowns["meteor"] > 0:
		return
	var mana_cost = 45.0 - (level - 1) * 2.0
	var cd = max(5.0 - (level - 1) * 0.2, 1.0)
	var damage = 250.0 + (level - 1) * 30.0
	var radius = 130.0 + (level - 1) * 10.0
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["meteor"] = cd
		_spawn_meteor(mouse_pos, damage, radius)

func _spawn_meteor(pos: Vector2, damage: float, radius: float):
	var timer = 0.0
	var tween = create_tween()
	tween.set_loops(20)
	tween.tween_callback(func():
		for i in range(3):
			var offset = Vector2(randf() * radius * 2 - radius, randf() * radius * 2 - radius)
			var meteor_pos = pos + offset
			_spawn_single_meteor(meteor_pos, damage)
	)
	tween.tween_interval(0.1)

func _spawn_single_meteor(pos: Vector2, damage: float):
	var meteor = Area2D.new()
	meteor.global_position = pos
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 15.0
	meteor.add_child(collision)
	get_parent().add_child(meteor)
	
	var visual = ColorRect.new()
	visual.color = Color(1.0, 0.3, 0.0, 0.8)
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	meteor.add_child(visual)
	
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		if is_instance_valid(meteor):
			for body in meteor.get_overlapping_bodies():
				if body.is_in_group("monsters"):
					body.take_damage(damage * Global.damage_multiplier, true)
			meteor.queue_free()
	)

func cast_armageddon():
	var level = Global.skill_levels.get("armageddon", 0)
	if level <= 0:
		return
	if skill_cooldowns["armageddon"] > 0:
		return
	var mana_cost = 55.0
	var cd = 20.0
	var blast_radius = 60.0 + (level - 1) * 2.0
	var blast_damage = 250.0 + (level - 1) * 10.0
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["armageddon"] = cd
		_spawn_armageddon(blast_damage, blast_radius)

func _spawn_armageddon(damage: float, radius: float):
	var map_size = 2000.0
	for i in range(20):
		var pos = Vector2(randf() * map_size - map_size / 2, randf() * map_size - map_size / 2)
		_spawn_fireblast(pos, damage, radius)
		await get_tree().create_timer(0.05).timeout

func _spawn_fireblast(pos: Vector2, damage: float, radius: float):
	var blast = Area2D.new()
	blast.global_position = pos
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = radius
	blast.add_child(collision)
	get_parent().add_child(blast)
	
	var visual = ColorRect.new()
	visual.color = Color(1.0, 0.5, 0.0, 0.6)
	visual.size = Vector2(radius * 2, radius * 2)
	visual.position = Vector2(-radius, -radius)
	blast.add_child(visual)
	
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		if is_instance_valid(blast):
			for body in blast.get_overlapping_bodies():
				if body.is_in_group("monsters"):
					body.take_damage(damage * Global.damage_multiplier, true)
			blast.queue_free()
	)

func _freeze_monster(monster, duration: float):
	if not is_instance_valid(monster):
		return
	# 保存原始速度
	var original_speed = monster.move_speed if "move_speed" in monster else 65.0
	monster.move_speed = 0.0
	if "can_attack" in monster:
		monster.can_attack = false
	if monster.has_node("Sprite2D"):
		monster.get_node("Sprite2D").modulate = Color(0.7, 0.9, 1.0)
	
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(monster):
		monster.move_speed = original_speed
		if "can_attack" in monster:
			monster.can_attack = true
		if monster.has_node("Sprite2D"):
			monster.get_node("Sprite2D").modulate = Color(1.0, 1.0, 1.0)

func cast_poison_cloud():
	var level = Global.skill_levels.get("poison_cloud", 0)
	if level <= 0:
		return
	if skill_cooldowns["poison_cloud"] > 0:
		return
	var mana_cost = 35.0
	var cd = max(5.0 - (level - 1) * 0.2, 1.0)
	var damage = 60.0 + (level - 1) * 20.0
	var radius = 110.0 + (level - 1) * 10.0
	var duration = 10.0 + (level - 1)
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["poison_cloud"] = cd
		_spawn_poison_cloud(mouse_pos, damage, radius, duration)

func _spawn_poison_cloud(pos: Vector2, damage: float, radius: float, duration: float):
	var cloud = Area2D.new()
	cloud.global_position = pos
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = radius
	cloud.add_child(collision)
	get_parent().add_child(cloud)
	
	var visual = ColorRect.new()
	visual.color = Color(0.2, 0.8, 0.2, 0.4)
	visual.size = Vector2(radius * 2, radius * 2)
	visual.position = Vector2(-radius, -radius)
	cloud.add_child(visual)
	
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(cloud.queue_free)
	
	var damage_tween = create_tween()
	damage_tween.set_loops(int(duration * 2))
	damage_tween.tween_callback(func():
		if is_instance_valid(cloud):
			for body in cloud.get_overlapping_bodies():
				if body.is_in_group("monsters"):
					body.take_damage(damage * 0.5 * Global.damage_multiplier, true)
	)
	damage_tween.tween_interval(0.5)

func cast_fortuna():
	var level = Global.skill_levels.get("fortuna", 0)
	if level <= 0:
		return
	if skill_cooldowns["fortuna"] > 0:
		return
	# 原版数据：LV10 +15%, LV15 +50%, LV19 +60%
	var bonus = 0.15 + (level - 10) * 0.05 if level > 10 else 0.15
	Global.drop_rate_multiplier = 1.0 + bonus
	skill_cooldowns["fortuna"] = 1.0

func cast_dark_ritual():
	var level = Global.skill_levels.get("dark_ritual", 0)
	if level <= 0:
		return
	if skill_cooldowns["dark_ritual"] > 0:
		return
	# 原版数据（技能等级1对应玩家等级25）：
	# LV1: 即死率30% 冷却5.5s 法力55 半径130
	# LV10: 即死率90% 冷却1.0s 法力77.5 半径130
	var kill_chance = min(0.3 + (level - 1) * 0.067, 0.9)
	var mana_cost = 55.0 + (level - 1) * 2.5
	var cd = max(5.5 - (level - 1) * 0.5, 1.0)
	var radius = 130.0
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["dark_ritual"] = cd
		_spawn_dark_ritual(mouse_pos, kill_chance, radius)

func _spawn_dark_ritual(pos: Vector2, kill_chance: float, radius: float):
	var ritual = Area2D.new()
	ritual.global_position = pos
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = radius
	ritual.add_child(collision)
	get_parent().add_child(ritual)
	
	var visual = ColorRect.new()
	visual.color = Color(0.0, 0.0, 0.0, 0.6)
	visual.size = Vector2(radius * 2, radius * 2)
	visual.position = Vector2(-radius, -radius)
	ritual.add_child(visual)
	
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func():
		if is_instance_valid(ritual):
			for body in ritual.get_overlapping_bodies():
				if body.is_in_group("monsters"):
					if randf() < kill_chance:
						body.take_damage(body.health * 2.0, true)
			ritual.queue_free()
	)
	
	var check_tween = create_tween()
	check_tween.set_loops(20)
	check_tween.tween_callback(func():
		if is_instance_valid(ritual):
			for body in ritual.get_overlapping_bodies():
				if body.is_in_group("monsters"):
					if randf() < kill_chance:
						body.take_damage(body.health * 2.0, true)
	)
	check_tween.tween_interval(0.1)

func cast_nova():
	var level = Global.skill_levels.get("nova", 0)
	if level <= 0:
		return
	if skill_cooldowns["nova"] > 0:
		return
	var mana_cost = 45.0
	var cd = max(2.0 - (level - 1) * 0.1, 0.5)
	var damage = 200.0 + (level - 1) * 10.0
	var radius = 100.0 + (level - 1) * 10.0
	var freeze_duration = 1.0 + (level - 1) * 0.2
	if Global.free_spells or Global.mana >= mana_cost:
		if not Global.free_spells:
			Global.mana -= mana_cost
			Global.mana_changed.emit(Global.mana, Global.max_mana)
		skill_cooldowns["nova"] = cd
		_spawn_nova(damage, radius, freeze_duration)

func _spawn_nova(damage: float, radius: float, freeze_duration: float):
	var direction = global_position.direction_to(mouse_pos)
	var snowball = Area2D.new()
	snowball.global_position = global_position
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 12.0
	snowball.add_child(collision)
	get_parent().add_child(snowball)
	
	var tween = create_tween()
	tween.tween_property(snowball, "global_position", global_position + direction * 300.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(snowball):
			snowball.queue_free()
	)
	
	var check_timer = 0.0
	while check_timer < 0.4:
		await get_tree().create_timer(0.05).timeout
		check_timer += 0.05
		if not is_instance_valid(snowball):
			return
		for body in snowball.get_overlapping_bodies():
			if body.is_in_group("monsters"):
				_explode_nova(snowball.global_position, damage, radius, freeze_duration)
				return

func _explode_nova(pos: Vector2, damage: float, radius: float, freeze_duration: float):
	var explosion = Area2D.new()
	explosion.global_position = pos
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = radius
	explosion.add_child(collision)
	get_parent().add_child(explosion)
	
	var visual = ColorRect.new()
	visual.color = Color(0.8, 0.9, 1.0, 0.5)
	visual.size = Vector2(radius * 2, radius * 2)
	visual.position = Vector2(-radius, -radius)
	explosion.add_child(visual)
	
	for body in explosion.get_overlapping_bodies():
		if body.is_in_group("monsters"):
			body.take_damage(damage * Global.damage_multiplier, true)
			_freeze_monster(body, freeze_duration)
	
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(explosion.queue_free)



func update_hud():
	$HealthBar.value = Global.health / Global.max_health * 100.0
	$ManaBar.value = Global.mana / Global.max_mana * 100.0
	$LevelLabel.text = "Lv." + str(Global.hero_level)

func _on_health_changed(h, _mh):
	$HealthBar.value = h / Global.max_health * 100.0

func _on_mana_changed(m, _mm):
	$ManaBar.value = m / Global.max_mana * 100.0

func _on_level_changed(lvl):
	$LevelLabel.text = "Lv." + str(lvl)
	show_level_up_effect()

func show_level_up_effect():
	var glow = ColorRect.new()
	glow.color = Color(1.0, 0.9, 0.3, 0.5)
	glow.size = Vector2(128, 128)
	glow.position = Vector2(-64, -64)
	add_child(glow)
	
	var tween = create_tween()
	tween.tween_property(glow, "color:a", 0.0, 2.0)
	tween.tween_callback(glow.queue_free)
	
	var label = Label.new()
	label.text = "LEVEL UP!"
	label.modulate = Color(1.0, 0.9, 0.0, 1.0)
	label.position = Vector2(-40, -80)
	add_child(label)
	
	var label_tween = create_tween()
	label_tween.tween_property(label, "position:y", -120, 2.0)
	label_tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	label_tween.tween_callback(label.queue_free)

func _on_died():
	visible = false
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)

func respawn():
	Global.reset()
	visible = true
	set_process(true)
	set_physics_process(true)
	set_process_unhandled_input(true)
	update_hud()
