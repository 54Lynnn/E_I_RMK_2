extends Node2D

# ============================================
# Prayer.gd - 祈祷技能专用脚本
# ============================================
# 这是祈祷技能的独立控制脚本，包含：
# - 技能配置（冷却、持续时间、生命消耗比例、法力恢复比例）
# - 持续效果系统（每秒扣血、每秒回蓝）
# - 蓝色气泡特效（每0.25秒产生一个，持续0.5秒后渐隐）
# - 跟随玩家（附加到玩家身上）
# ============================================

# ============================================
# 技能配置
# ============================================
static var skill_name := "prayer"
static var skill_type := "active"  # 技能类型: active, toggle, passive
static var base_cooldown := 20.0
static var base_duration := 10.0
static var base_health_cost_percent := 0.03  # 每秒扣除3%最大生命值
static var health_cost_reduction_per_level := 0.0015  # 每级减少0.15%
static var base_mana_restore_percent := 0.05  # 每秒恢复5%最大法力值
static var mana_restore_increase_per_level := 0.005  # 每级增加0.5%
static var bubble_interval := 0.25  # 气泡产生间隔
static var bubble_lifetime := 0.5  # 气泡持续时间

# ============================================
# 实例变量（运行时状态）
# ============================================
var hero: Node = null
var level: int = 0
var is_active: bool = false

@onready var bubble_timer: Timer = $BubbleTimer
@onready var duration_timer: Timer = $DurationTimer

# ============================================
# 等级成长公式
# ============================================
static func get_health_cost_percent(level: int) -> float:
	# LV1=3.0%, LV10=1.65%
	return max(base_health_cost_percent - (level - 1) * health_cost_reduction_per_level, 0.005)

static func get_mana_restore_percent(level: int) -> float:
	# LV1=5.0%, LV10=9.5%
	return base_mana_restore_percent + (level - 1) * mana_restore_increase_per_level

# ============================================
# 施法入口（静态方法，由 hero.gd 调用）
# ============================================
static func cast(hero_node: Node, _mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false
	
	# Prayer 不消耗法力，只消耗生命值
	# 检查玩家是否还活着（生命值 > 0）
	if Global.health <= 0:
		return false
	
	# 创建 Prayer 实例并附加到玩家
	var prayer_instance = preload("res://Scenes/Prayer.tscn").instantiate()
	prayer_instance.hero = hero_node
	prayer_instance.level = level
	hero_node.add_child(prayer_instance)
	prayer_instance.start()
	
	# 设置冷却
	skill_cooldowns[skill_name] = base_cooldown
	return true

# ============================================
# 实例方法：启动 Prayer 效果
# ============================================
func start():
	is_active = true
	
	# 启动气泡定时器
	bubble_timer.wait_time = bubble_interval
	bubble_timer.timeout.connect(_on_bubble_timer_timeout)
	bubble_timer.start()
	
	# 启动持续时间定时器
	duration_timer.wait_time = base_duration
	duration_timer.timeout.connect(_on_duration_timer_timeout)
	duration_timer.start()
	
	# 立即产生第一个气泡
	_spawn_bubble()
	
	# 启动持续效果（扣血、回蓝）
	_start_periodic_effects()

# ============================================
# 持续效果：每秒扣血、每秒回蓝
# ============================================
func _start_periodic_effects():
	var health_cost_percent = get_health_cost_percent(level)
	var mana_restore_percent = get_mana_restore_percent(level)
	
	# 使用 Timer 每秒执行一次效果
	var effect_timer = Timer.new()
	effect_timer.wait_time = 1.0
	effect_timer.one_shot = false
	add_child(effect_timer)
	
	effect_timer.timeout.connect(func():
		if not is_active or hero == null:
			effect_timer.stop()
			effect_timer.queue_free()
			return
		
		# 每秒扣除生命值（百分比）
		var health_cost = Global.max_health * health_cost_percent
		Global.health = max(Global.health - health_cost, 1.0)  # 至少保留1点生命，避免自杀
		Global.health_changed.emit(Global.health, Global.max_health)
		
		# 每秒恢复法力值（百分比）
		var mana_restore = Global.max_mana * mana_restore_percent
		Global.mana = min(Global.mana + mana_restore, Global.max_mana)
		Global.mana_changed.emit(Global.mana, Global.max_mana)
	)
	
	effect_timer.start()
	
	# 连接持续时间结束信号，停止效果
	duration_timer.timeout.connect(func():
		effect_timer.stop()
		effect_timer.queue_free()
	)

# ============================================
# 气泡特效
# ============================================
func _on_bubble_timer_timeout():
	if is_active:
		_spawn_bubble()

func _spawn_bubble():
	if hero == null:
		return
	
	# 创建气泡（使用 Sprite2D + Tween 实现）
	var bubble = Sprite2D.new()
	
	# 创建圆形纹理（更大的气泡）
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
	
	# 随机偏移位置（玩家周围，从身体下方产生）
	var random_offset = Vector2(randf_range(-20, 20), randf_range(5, 20))
	bubble.position = random_offset
	
	# 添加气泡到 Prayer 节点（跟随玩家）
	# 设置 z_index 确保气泡显示在玩家上方
	bubble.z_index = 10
	add_child(bubble)
	
	# 使用 Tween 实现上浮和渐隐
	var tween = create_tween()
	
	# 上浮动画
	tween.parallel().tween_property(bubble, "position:y", bubble.position.y - 30, bubble_lifetime)
	
	# 渐隐动画
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, bubble_lifetime)
	
	# 动画结束后删除气泡（检查气泡是否还存在）
	tween.finished.connect(func():
		if is_instance_valid(bubble):
			bubble.queue_free()
	)

# ============================================
# 持续时间结束
# ============================================
func _on_duration_timer_timeout():
	is_active = false
	
	# 停止气泡定时器
	bubble_timer.stop()
	
	# 清理所有剩余气泡
	for child in get_children():
		if child is Sprite2D and is_instance_valid(child) and child != bubble_timer and child != duration_timer:
			child.queue_free()
	
	# 延迟后删除自身
	await get_tree().create_timer(1.0).timeout
	queue_free()
