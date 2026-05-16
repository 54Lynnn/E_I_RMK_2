extends CharacterBody2D

# ============================================
# MonsterBase.gd - 怪物基础类
# ============================================
# 这是所有怪物的父类（基类），提供通用功能。
#
# 继承关系：
#   MonsterBase (这个文件)
#   ├── MonsterMelee (monster_melee.gd) - 近战怪物基类
#   │   ├── MonsterSpider - 蜘蛛
#   │   ├── MonsterZombie - 僵尸
#   │   ├── MonsterBear - 熊
#   │   ├── MonsterDemon - 恶魔
#   │   ├── MonsterReaper - 死神
#   │   └── MonsterBoss - Boss
#   └── MonsterRanged (monster_ranged.gd) - 远程怪物基类
#       └── MonsterArcher - 弓手
#
# 子类必须重写的方法：
#   _process_behavior(delta) - 定义怪物的行为逻辑
#
# 子类可以选择重写的方法：
#   _calculate_resistance(damage_element) - 自定义伤害抗性
#   _ready() - 自定义初始化（记得调用 super._ready()）
# ============================================

const MonsterDatabase = preload("res://Scripts/Monsters/monster_database.gd")

# ============================================
# 怪物ID（用于从数据库读取数值）
# ============================================
# 子类必须设置这个值，例如：
#   monster_id = "spider"
# 如果为空，则使用 @export 的默认值
@export var monster_id := ""         # 怪物在数据库中的ID

# ============================================
# 基础属性（所有怪物都有）
# ============================================
# 这些属性可以通过 monster_database.gd 集中配置
# 也可以在 .tscn 场景文件中单独配置（会覆盖数据库值）
# 通过 @export 可以在 Godot 编辑器中直接修改数值

@export var move_speed := 65.0       # 移动速度（像素/秒）：怪物跑得多快
@export var health := 30.0           # 当前血量：怪物现在有多少血
@export var max_health := 30.0       # 最大血量：怪物的血量上限
@export var damage := 5.0            # 攻击力：每次攻击造成多少伤害
@export var collision_damage := 2.0  # 碰撞伤害：撞到玩家时造成的伤害
@export var experience_reward := 30  # 经验奖励：击败后玩家获得多少经验

@export var detection_range: float   # 检测范围（像素）：怪物能发现玩家的最远距离
@export var attack_range: float      # 攻击范围（像素）：怪物可以发动攻击的距离
@export var min_distance := 40.0     # 最小距离（像素）：避免怪物贴脸穿模
@export var attack_cooldown := 2.0   # 攻击间隔（秒）：两次攻击之间的等待时间
@export var rotation_speed := 1.0    # 转向速度：越大转向越快，0.4=笨重，1.5=灵活

# ============================================
# 元素光环（Aura）系统
# ============================================
# 每个怪物生成时随机获得一种元素光环
# 有光环的怪物受到对应属性伤害时减免50%
#
# 光环类型：
# - "basic" (紫色)：减免 basic 属性伤害
# - "earth" (灰色)：减免 earth 属性伤害
# - "air"   (白色)：减免 air 属性伤害
# - "fire"  (橙红)：减免 fire 属性伤害
# - "water" (蓝色)：减免 water 属性伤害
# - ""      (无)：没有光环，不减免

@export var elemental_aura := ""     # 元素光环类型（空字符串=无光环）
const AURA_RESISTANCE := 0.5         # 光环减伤比例：50%（减免对应属性伤害的一半）
const AURA_RADIUS := 20.0            # 光环圆环半径（像素）：距离怪物中心20px
const AURA_WIDTH := 4.0              # 光环圆环宽度（像素）
const AURA_Z_INDEX := 11             # 光环显示层级：比怪物(z=10)高一层

# ============================================
# 状态机
# ============================================
# 怪物有5种状态，用枚举(enum)定义：
# - IDLE: 待机（停止移动，等待玩家）
# - CHASE: 追击（向玩家移动）
# - ATTACK: 攻击（正在执行攻击动作）
# - HURT: 受击（被攻击后的短暂硬直）
# - DEATH: 死亡（正在播放死亡动画）

enum State { IDLE, CHASE, ATTACK, HURT, DEATH }
var current_state := State.IDLE      # 当前状态，初始为待机

# ============================================
# 运行时变量
# ============================================
var target: Node2D = null            # 当前目标：通常是玩家（Hero节点）
var can_attack := true               # 是否可以攻击：受冷却时间控制
var original_move_speed := 65.0      # 记录原始速度：用于debuff后恢复

# 游荡行为变量（所有模式都适用）
var wander_mode := true              # 是否启用游荡行为（默认启用）
var wander_direction := Vector2.ZERO # 游荡方向
var map_bounds := Rect2(0, 0, 1536, 1536)  # 地图边界（用于反弹计算）

# 击退系统（用于遗物 knockback_missile）
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

# 行走动画变量
var anim_frame := 0
var anim_timer := 0.0
@export var frame_size := 48       # 精灵帧尺寸（Diablo 用 64）
const FRAME_GAP := 2               # spritesheet 帧间距
const ANIM_SPEED := 0.12           # 行走每帧间隔（秒）

# 攻击/死亡动画状态
enum AnimState { WALK, ATTACK, DEATH }
var anim_state := AnimState.WALK
var combat_frame := 0
var combat_timer := 0.0
const COMBAT_SPEED := 0.08         # 攻击/死亡每帧间隔（秒）
const ATTACK_FRAMES := 16
const DEATH_FRAMES := 16

# 预加载的纹理
var attack_texture: Texture2D = null
var death_texture: Texture2D = null
var walk_texture: Texture2D = null

# ============================================
# 节点引用
# ============================================
# @onready 表示在 _ready() 时自动获取这些节点
# 这些节点必须在每个怪物的 .tscn 中存在

@onready var sprite := $Sprite2D          # Sprite2D节点：怪物的贴图
@onready var health_bar := $HealthBar     # ProgressBar节点：头顶血条
@onready var state_timer := $StateTimer   # Timer节点：状态计时器
@onready var attack_cooldown_timer := $AttackCooldown  # Timer节点：攻击冷却
var aura_sprite: Sprite2D = null         # Sprite2D节点：元素光环圆环（可选，动态创建）

# ============================================
# debuff系统
# ============================================
# debuffs 是一个字典，记录当前身上的所有debuff效果
# 格式：{"debuff名称": {"remaining": 剩余时间, "duration": 总时长, "params": 参数}}
var debuffs := {}

# ============================================
# _ready(): 初始化函数
# ============================================
# 怪物被创建时自动调用，设置初始状态
func _ready():
	# 加入"monsters"分组，方便其他脚本查找所有怪物
	add_to_group("monsters")
	
	# 【数据库系统】由生成器（Spawner）统一调用 apply_database_data()
	# 数值统一在 monster_database.gd 中管理
	
	# 记录原始速度（用于debuff后恢复）
	original_move_speed = move_speed
	
	# 设置血条（安全检查）
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		# 如果Alt模式已开启，直接显示血条
		if Global.show_monster_info:
			health_bar.visible = true
	
	# 初始朝向
	if sprite:
		sprite.rotation = 0
		# 加载攻击/死亡动画纹理
		_load_animation_textures()
	
	# 【光环系统】随机分配元素光环（如果未指定）
	# 50%概率无光环，50%概率随机一种光环
	if elemental_aura == "":
		if randf() < 0.5:
			# 50%概率：无光环
			elemental_aura = ""
		else:
			# 50%概率：随机一种光环
			var auras = ["basic", "earth", "air", "fire", "water"]
			elemental_aura = auras[randi() % auras.size()]
	
	# 【光环系统】创建光环视觉效果（只有有光环时才创建）
	if elemental_aura != "":
		_create_aura_visual()
	
	# 设置状态计时器
	# wait_time = 1.0 + 随机0~2秒，让每个怪物的计时器不同步
	state_timer.wait_time = 1.0 + randf() * 2.0
	state_timer.timeout.connect(_on_state_timer_timeout)
	state_timer.start()
	
	# 连接攻击冷却计时器
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	
	# 【游荡行为】初始化游荡方向
	if wander_mode:
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

# ============================================
# 从数据库加载数值（旧方法，保留兼容）
# ============================================
func _load_data_from_database():
	var data = MonsterDatabase.get_monster_data(monster_id, Global.hero_level, Global.current_difficulty, Global.current_game_mode == Global.GameMode.SURVIVAL)
	if data.is_empty():
		push_error("MonsterBase: 无法从数据库加载怪物数据: " + monster_id)
		return
	apply_database_data(data)

# ============================================
# 应用数据库数据（由生成器调用）
# ============================================
func apply_database_data(data: Dictionary):
	# 应用所有属性
	move_speed = data.get("move_speed", move_speed)
	health = data.get("health", health)
	max_health = data.get("max_health", max_health)
	damage = data.get("damage", damage)
	collision_damage = data.get("collision_damage", collision_damage)
	experience_reward = data.get("experience_reward", experience_reward)
	detection_range = data.get("detection_range", detection_range)
	attack_range = data.get("attack_range", attack_range)
	min_distance = data.get("min_distance", min_distance)
	attack_cooldown = data.get("attack_cooldown", attack_cooldown)
	rotation_speed = data.get("rotation_speed", rotation_speed)
	
	# 更新血条（如果已初始化）
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	
	# 记录原始速度
	original_move_speed = move_speed

# ============================================
# 游荡模式设置
# ============================================
func set_quest_mode(enabled: bool):
	"""设置游荡模式：怪物会随机游荡，直到发现玩家"""
	wander_mode = enabled
	if enabled:
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func set_experience_reward(value: int):
	"""设置经验奖励（用于Quest模式达到上限时）"""
	experience_reward = value

func get_current_health() -> float:
	"""获取当前血量（用于Quest模式检查怪物是否存活）"""
	return health

func set_wander_direction(dir: Vector2):
	"""设置游荡方向（由生成器调用，如整排横扫的方向）"""
	if dir.length() > 0:
		wander_direction = dir.normalized()
		wander_mode = true

func set_knockback(velocity: Vector2, duration: float):
	knockback_velocity = velocity
	knockback_timer = duration

# ============================================
# _physics_process(): 每帧物理更新
# ============================================
# 这是游戏循环的核心函数，每帧都会执行
# delta = 距离上一帧的时间（秒），用于保证不同帧率下行为一致
func _physics_process(delta):
	# 更新动画（包括死亡动画，需要在判断 DEATH 前执行）
	_update_animation(delta)
	
	if current_state == State.DEATH:
		return
	
	_process_debuffs(delta)
	
	find_target()
	
	if wander_mode and target == null:
		_process_wandering(delta)
	else:
		_process_behavior(delta)
	
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_velocity
		if knockback_timer <= 0:
			knockback_velocity = Vector2.ZERO
	
	move_and_slide()

# ============================================
# 行走动画更新
# ============================================
func _update_animation(delta):
	if not sprite:
		return
	
	match anim_state:
		AnimState.ATTACK:
			combat_timer += delta
			if combat_timer >= COMBAT_SPEED:
				combat_timer = 0.0
				combat_frame += 1
				if combat_frame >= ATTACK_FRAMES:
					anim_state = AnimState.WALK
					combat_frame = 0
					sprite.texture = walk_texture
			if monster_id == "spider":
				sprite.region_rect = Rect2(0, 0, frame_size, frame_size)
			else:
				var x = combat_frame * (frame_size + FRAME_GAP)
				sprite.region_rect = Rect2(x, 0, frame_size, frame_size)
			return
		
		AnimState.DEATH:
			combat_timer += delta
			if combat_timer >= COMBAT_SPEED:
				combat_timer = 0.0
				combat_frame += 1
				if combat_frame >= DEATH_FRAMES:
					queue_free()
					return
			var x = combat_frame * (frame_size + FRAME_GAP)
			sprite.region_rect = Rect2(x, 0, frame_size, frame_size)
			return
	
	# AnimState.WALK
	var is_moving = velocity.length() > 10.0
	if is_moving:
		anim_timer += delta
		if anim_timer >= ANIM_SPEED:
			anim_timer = 0.0
			anim_frame = (anim_frame + 1) % 16
	else:
		anim_frame = 0
		anim_timer = 0.0
	var x = anim_frame * (frame_size + FRAME_GAP)
	sprite.region_rect = Rect2(x, 0, frame_size, frame_size)

func _load_animation_textures():
	if monster_id == "":
		return
	var base_path = "res://Art/Placeholder/monster_%s"
	walk_texture = sprite.texture
	attack_texture = load(base_path % (monster_id + "_attack.png"))
	death_texture = load(base_path % (monster_id + "_death.png"))

func play_attack_animation():
	if anim_state == AnimState.DEATH:
		return
	anim_state = AnimState.ATTACK
	combat_frame = 0
	combat_timer = 0.0
	if attack_texture and monster_id != "spider":
		sprite.texture = attack_texture
	elif sprite:
		sprite.modulate = Color(1, 0.5, 0.5)
		var t = create_tween()
		t.tween_property(sprite, "modulate", Color.WHITE, 0.15)

# ============================================
# 平滑转向（让怪物转头更自然）
# ============================================
func rotate_towards(direction: Vector2, delta: float):
	if not sprite or direction.length() <= 0.001:
		return
	var target_angle = atan2(direction.y, direction.x)
	var angle_diff = wrapf(target_angle - sprite.rotation, -PI, PI)
	var step = rotation_speed * 4.0 * delta  # 转换为实际角速度
	if abs(angle_diff) < step:
		sprite.rotation = target_angle
	else:
		sprite.rotation += sign(angle_diff) * step

# ============================================
# 游荡逻辑（带墙壁反弹）
# ============================================
func _process_wandering(delta):
	"""怪物随机游荡（所有模式都适用）
	碰到墙壁会像光线反射一样反弹"""
	
	# 检查是否碰到墙壁并反弹
	_check_wall_bounce()
	
	# 设置游荡速度（正常移动速度）
	velocity = wander_direction * move_speed
	current_state = State.IDLE
	
	# 平滑转向移动方向
	rotate_towards(wander_direction, delta)

func _check_wall_bounce():
	"""检查是否碰到墙壁，碰到后随机选一个新方向"""
	var margin := 50.0
	var hit_wall := false
	var wall_normal := Vector2.ZERO  # 墙壁的法线方向
	
	# 检查左右墙壁
	if global_position.x <= map_bounds.position.x + margin:
		if wander_direction.x < 0:
			hit_wall = true
			wall_normal = Vector2.RIGHT
	elif global_position.x >= map_bounds.position.x + map_bounds.size.x - margin:
		if wander_direction.x > 0:
			hit_wall = true
			wall_normal = Vector2.LEFT
	
	# 检查上下墙壁
	if not hit_wall:
		if global_position.y <= map_bounds.position.y + margin:
			if wander_direction.y < 0:
				hit_wall = true
				wall_normal = Vector2.DOWN
		elif global_position.y >= map_bounds.position.y + map_bounds.size.y - margin:
			if wander_direction.y > 0:
				hit_wall = true
				wall_normal = Vector2.UP
	
	if hit_wall:
		# 随机选一个新方向（偏向于远离墙壁的方向）
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		# 如果新方向指向墙壁，反转它（防止卡墙）
		if wander_direction.dot(wall_normal) < 0:
			wander_direction = -wander_direction

# ============================================
# _process_behavior(): 怪物行为逻辑
# ============================================
# 【重要】这是抽象方法，子类必须重写！
# 基类不提供默认实现，如果子类没重写会打印警告
#
# 子类在这个方法中定义：
# - 什么时候移动
# - 什么时候攻击
# - 特殊能力如何触发
func _process_behavior(delta):
	# 基类不提供默认实现，子类必须重写
	push_warning("_process_behavior() not implemented in subclass")

# ============================================
# 目标查找
# ============================================
# 查找场景中的玩家（Hero节点）
# 玩家必须在"hero"分组中
func find_target():
	# 获取所有在"hero"分组中的节点
	var heroes = get_tree().get_nodes_in_group("hero")
	
	if heroes.size() > 0:
		var hero = heroes[0]  # 假设只有一个玩家
		var dist = global_position.distance_to(hero.global_position)
		
		# 如果玩家在检测范围内且可见，设为当前目标
		if dist <= detection_range and hero.visible:
			target = hero
		else:
			target = null
	else:
		target = null

# ============================================
# 攻击玩家（近战）
# ============================================
# 对玩家造成伤害（近战攻击）
# 由子类在合适的时机调用
func perform_attack():
	if target and can_attack:
		can_attack = false
		if attack_cooldown_timer:
			attack_cooldown_timer.start(attack_cooldown)
		
		play_attack_animation()
		
		var dist = target.global_position.distance_to(global_position)
		if dist <= attack_range + 20.0:
			Global.take_damage(damage, false, self)

# ============================================
# 攻击冷却结束
# ============================================
func _on_attack_cooldown_timeout():
	can_attack = true

# ============================================
# 受击处理
# ============================================
# 当怪物受到伤害时调用
# 参数：
#   amount: 伤害数值
#   damage_element: 伤害属性（basic, earth, air, fire, water）
func take_damage(amount: float, damage_element: String = "basic"):
	# 如果已死亡，不再受伤
	if current_state == State.DEATH:
		return
	
	# 计算伤害抗性（子类可重写 _calculate_resistance）
	var resist := _calculate_resistance(damage_element)
	
	# 应用抗性减免
	amount *= (1.0 - resist)
	
	# 扣血
	health -= amount
	if health_bar:
		health_bar.value = health
		if Global.show_monster_info:
			health_bar.visible = health > 0
		else:
			health_bar.visible = true  # 受伤时临时显示血条
			if health <= 0:
				health_bar.visible = false
	
	# 显示伤害数字（Alt键开启时）
	if Global.show_monster_info and amount > 0:
		_show_damage_number(amount)
	
	# 受击闪烁效果：变红后0.1秒恢复
	if sprite:
		var flash_tween = create_tween()
		sprite.modulate = Color(1, 0.3, 0.3)  # 红色
		flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# 判断是否死亡
	if health <= 0:
		die()
	else:
		# 进入受击状态，0.3秒后恢复
		current_state = State.HURT
		if state_timer:
			state_timer.start(0.3)

# ============================================
# 计算伤害抗性（子类可重写）
# ============================================
# 默认检查元素光环抗性
# 如果伤害属性与光环匹配，减免50%伤害
#
# 参数：damage_element - 伤害属性
# 返回：抗性比例（0.0 = 无抗性, 0.5 = 50%减伤, 1.0 = 完全免疫）
func _calculate_resistance(damage_element: String) -> float:
	# 【光环系统】如果光环已激活且伤害属性匹配
	if elemental_aura != "" and damage_element == elemental_aura:
		return AURA_RESISTANCE  # 返回50%减伤
	
	# 不匹配，无抗性
	return 0.0

# ============================================
# 创建光环视觉效果
# ============================================
# 在怪物周围创建一个圆环，表示元素光环
# 圆环距离怪物中心20px，宽度4px，层级11
func _create_aura_visual():
	# 如果已经有 AuraSprite 节点，使用它
	if has_node("AuraSprite"):
		aura_sprite = $AuraSprite
		_update_aura_color()
		return
	
	# 否则创建一个新的 Sprite2D 作为光环
	var aura = Sprite2D.new()
	aura.name = "AuraSprite"
	aura.z_index = AURA_Z_INDEX
	aura.position = Vector2.ZERO  # 居中
	
	# 创建圆环贴图（使用 ViewportTexture 或简单圆形）
	# 这里使用 Godot 的 CanvasItem 绘制功能
	var texture = _create_ring_texture()
	aura.texture = texture
	
	# 设置颜色
	_update_aura_color(aura)
	
	# 添加到怪物节点
	add_child(aura)
	aura_sprite = aura

# ============================================
# 创建圆环贴图
# ============================================
# 使用 ImageTexture 创建一个圆环形状
func _create_ring_texture() -> ImageTexture:
	var size = int((AURA_RADIUS + AURA_WIDTH) * 2.0) + 4
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # 透明背景
	
	var center = Vector2(size / 2, size / 2)
	var inner_radius = AURA_RADIUS - AURA_WIDTH / 2.0
	var outer_radius = AURA_RADIUS + AURA_WIDTH / 2.0
	
	# 绘制圆环
	for x in range(size):
		for y in range(size):
			var dist = center.distance_to(Vector2(x, y))
			if dist >= inner_radius and dist <= outer_radius:
				image.set_pixel(x, y, Color(1, 1, 1, 1))  # 白色（会被 modulate 染色）
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# ============================================
# 更新光环颜色
# ============================================
# 根据元素类型设置光环颜色
func _update_aura_color(aura: Sprite2D = null):
	if aura == null:
		aura = aura_sprite
	if aura == null:
		return
	
	var aura_color: Color
	match elemental_aura:
		"basic":
			aura_color = Color(0.75, 0.52, 0.99)  # 紫粉色
		"earth":
			aura_color = Color(0.63, 0.52, 0.13)  # 黄棕色
		"air":
			aura_color = Color(0.78, 0.78, 0.78)  # 银白色
		"fire":
			aura_color = Color(0.85, 0.29, 0.16)  # 红色
		"water":
			aura_color = Color(0.23, 0.50, 1.0)   # 蓝色
		_:
			aura_color = Color(0.75, 0.52, 0.99)  # 默认紫粉色
	
	aura.modulate = aura_color

func _show_damage_number(amount: float):
	var label = Label.new()
	label.text = str(int(amount))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)
	label.position = global_position + Vector2(-20, -40)
	label.size = Vector2(40, 24)
	get_parent().add_child(label)
	var tween = get_tree().create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

# ============================================
# 死亡处理
# ============================================
func die():
	if current_state == State.DEATH:
		return
	
	current_state = State.DEATH
	anim_state = AnimState.DEATH
	combat_frame = 0
	combat_timer = 0.0
	debuffs.clear()
	if health_bar:
		health_bar.visible = false
	
	set_collision_layer_value(3, false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	Global.gain_experience(experience_reward)
	LootManager.try_drop(global_position, get_parent())
	
	if Global.current_game_mode == Global.GameMode.QUEST:
		var quest_manager = get_tree().get_first_node_in_group("quest_level_manager")
		if quest_manager:
			quest_manager.on_monster_killed()
	
	if death_texture:
		sprite.texture = death_texture
	
	if aura_sprite:
		var death_duration = DEATH_FRAMES * COMBAT_SPEED
		var aura_tween = create_tween()
		aura_tween.tween_property(aura_sprite, "modulate:a", 0.0, death_duration)
	
	# 死亡动画由 _update_animation 驱动，播完自动 queue_free

# ============================================
# debuff系统
# ============================================

# 添加debuff
# 参数：
#   name: debuff名称（如"frozen", "slowed"）
#   duration: 持续时间（秒）
#   params: 额外参数（如减速比例）
#   debuff_element: debuff的属性（basic, earth, air, fire, water）
#                   如果与怪物aura匹配，效果减半
func apply_debuff(name: String, duration: float, params: Dictionary = {}, debuff_element: String = ""):
	if current_state == State.DEATH:
		return
	
	# 【光环系统】如果debuff属性与怪物aura匹配，效果减半
	if debuff_element != "" and elemental_aura != "" and debuff_element == elemental_aura:
		duration *= 0.5  # 持续时间减半
		# 减速效果也减半
		if params.has("factor"):
			params["factor"] *= 0.5
	
	# 如果已有同名debuff，刷新持续时间
	if debuffs.has(name):
		debuffs[name].remaining = duration
		debuffs[name].params = params
	else:
		# 添加新debuff
		debuffs[name] = {
			"remaining": duration,
			"duration": duration,
			"params": params
		}
		_on_debuff_applied(name)

# 移除debuff
func remove_debuff(name: String):
	if not debuffs.has(name):
		return
	
	var params = debuffs[name].params
	debuffs.erase(name)
	
	if current_state == State.DEATH:
		return
	
	_on_debuff_removed(name, params)

# 检查是否有某个debuff
func has_debuff(name: String) -> bool:
	return debuffs.has(name)

# 处理debuff倒计时
func _process_debuffs(delta):
	var expired = []
	
	# 遍历所有debuff，减少剩余时间
	for name in debuffs:
		debuffs[name].remaining -= delta
		if debuffs[name].remaining <= 0:
			expired.append(name)
	
	# 移除过期的debuff
	for name in expired:
		remove_debuff(name)

# debuff被添加时的处理
func _on_debuff_applied(name: String):
	match name:
		"frozen":  # 冰冻：无法移动和攻击
			move_speed = 0.0
			can_attack = false
			velocity = Vector2.ZERO
			if sprite:
				sprite.modulate = Color(0.5, 0.8, 1.0)  # 蓝色
		
		"slowed":  # 减速：移动速度降低
			# 如果已经有冰冻或石化，不覆盖速度（保持为0）
			if debuffs.has("frozen") or debuffs.has("petrified"):
				return
			var factor = debuffs[name].params.get("factor", 0.5)
			move_speed = original_move_speed * clamp(1.0 - factor, 0.0, 1.0)
		
		"petrified":  # 石化：无法移动和攻击，变灰
			move_speed = 0.0
			can_attack = false
			velocity = Vector2.ZERO
			if sprite:
				sprite.modulate = Color(0.3, 0.3, 0.3)

# debuff被移除时的处理
func _on_debuff_removed(name: String, params: Dictionary = {}):
	if current_state == State.DEATH:
		return
	
	match name:
		"frozen":  # 解除冰冻：恢复速度和攻击
			move_speed = original_move_speed
			can_attack = true
			if sprite:
				sprite.modulate = Color.WHITE
		
		"slowed":  # 解除减速：重新计算速度
			_recalculate_speed()
		
		"petrified":  # 解除石化：死亡（石化解除时碎裂）
			die()
		
		"dark_ritual":  # 黑暗仪式：概率即死或受到伤害
			var chance = params.get("chance", 0.3)
			var dmg = params.get("damage", 100.0)
			# 【光环系统】如果怪物有 water aura，伤害减半（即死变普通伤害）
			if elemental_aura == "water":
				take_damage(dmg * 0.5, "water")  # water aura：即死被抵抗，改为减半伤害
			else:
				if randf() < chance:
					take_damage(99999.0, "water")  # 即死
				else:
					take_damage(dmg, "water")

# 重新计算移动速度（考虑所有debuff）
func _recalculate_speed():
	move_speed = original_move_speed
	
	# 如果有冰冻或石化，速度直接为0（优先级最高）
	if debuffs.has("frozen") or debuffs.has("petrified"):
		move_speed = 0.0
		return
	
	for name in debuffs:
		var d = debuffs[name]
		match name:
			"slowed":
				var factor = d.params.get("factor", 0.5)
				move_speed *= clamp(1.0 - factor, 0.0, 1.0)

# ============================================
# 状态计时器超时
# ============================================
func _on_state_timer_timeout():
	# 受击状态结束，恢复追击或待机
	if current_state == State.HURT:
		current_state = State.CHASE if target else State.IDLE
