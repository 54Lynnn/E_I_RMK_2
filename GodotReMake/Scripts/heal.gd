extends Node2D

# ============================================
# Heal.gd - 治疗技能专用脚本
# ============================================
# 这是治疗技能的独立控制脚本，包含：
# - 技能配置（冷却、法力消耗、生命恢复比例）
# - 持续效果系统（每秒回血）
# - 红色+号特效（每0.25秒产生一个，持续0.5秒后渐隐）
# - 跟随玩家（附加到玩家身上）
# ============================================

# ============================================
# 技能配置
# ============================================
static var skill_name := "heal"
static var skill_type := "active"  # 技能类型: active, toggle, passive
static var base_cooldown := 15.0
static var base_duration := 10.0
static var base_mana_cost := 35.0
static var mana_cost_increase_per_level := 2.0  # 每级法力消耗+2
static var base_health_restore_percent := 0.055  # 每秒恢复5.5%最大生命值
static var health_restore_increase_per_level := 0.0025  # 每级增加0.25%
static var plus_interval := 0.25  # +号产生间隔
static var plus_lifetime := 0.5  # +号持续时间

# ============================================
# 实例变量（运行时状态）
# ============================================
var hero: Node = null
var level: int = 0
var is_active: bool = false

@onready var plus_timer: Timer = $PlusTimer
@onready var duration_timer: Timer = $DurationTimer

# ============================================
# 等级成长公式
# ============================================
static func get_mana_cost(level: int) -> float:
	return 35.0 + (level - 1) * 2.0

static func get_cooldown(level: int) -> float:
	return 15.0 + (level - 1) * 1.0

static func get_health_restore_percent(level: int) -> float:
	return 0.055 + (level - 1) * 0.05

# ============================================
# 施法入口（静态方法，由 hero.gd 调用）
# ============================================
static func cast(hero_node: Node, _mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
	var level = Global.skill_levels.get(skill_name, 0)
	if level <= 0:
		return false
	if skill_cooldowns.get(skill_name, 0.0) > 0:
		return false
	
	var mana_cost = get_mana_cost(level)
	var cooldown = get_cooldown(level)
	
	# 检查法力值
	if not Global.free_spells and Global.mana < mana_cost:
		return false
	
	# 扣除法力值
	if not Global.free_spells:
		Global.mana -= mana_cost
		Global.mana_changed.emit(Global.mana, Global.max_mana)
	
	# 创建 Heal 实例并附加到玩家
	var heal_instance = preload("res://Scenes/Heal.tscn").instantiate()
	heal_instance.hero = hero_node
	heal_instance.level = level
	hero_node.add_child(heal_instance)
	heal_instance.start()
	
	# 设置冷却
	skill_cooldowns[skill_name] = cooldown
	return true

# ============================================
# 实例方法：启动 Heal 效果
# ============================================
func start():
	is_active = true
	
	# 启动+号定时器
	plus_timer.wait_time = plus_interval
	plus_timer.timeout.connect(_on_plus_timer_timeout)
	plus_timer.start()
	
	# 启动持续时间定时器
	duration_timer.wait_time = base_duration
	duration_timer.timeout.connect(_on_duration_timer_timeout)
	duration_timer.start()
	
	# 立即产生第一个+号
	_spawn_plus()
	
	# 启动持续效果（回血）
	_start_periodic_effects()

# ============================================
# 持续效果：每秒回血
# ============================================
func _start_periodic_effects():
	var health_restore_percent = get_health_restore_percent(level)
	
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
		
		# 每秒恢复生命值（百分比）
		var health_restore = Global.max_health * health_restore_percent
		Global.health = min(Global.health + health_restore, Global.max_health)
		Global.health_changed.emit(Global.health, Global.max_health)
	)
	
	effect_timer.start()
	
	# 连接持续时间结束信号，停止效果
	duration_timer.timeout.connect(func():
		effect_timer.stop()
		effect_timer.queue_free()
	)

# ============================================
# +号特效
# ============================================
func _on_plus_timer_timeout():
	if is_active:
		_spawn_plus()

func _spawn_plus():
	if hero == null:
		return
	
	# 创建+号（使用 Label + Tween 实现）
	var plus_label = Label.new()
	plus_label.text = "+"
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 0.9))
	plus_label.add_theme_font_size_override("font_size", 24)
	
	# 随机偏移位置（玩家周围）
	var random_offset = Vector2(randf_range(-20, 20), randf_range(-10, 10))
	plus_label.position = random_offset
	
	# 设置 z_index 确保显示在玩家上方
	plus_label.z_index = 10
	
	# 添加+号到 Heal 节点（跟随玩家）
	add_child(plus_label)
	
	# 使用 Tween 实现上浮和渐隐
	var tween = create_tween()
	
	# 上浮动画
	tween.parallel().tween_property(plus_label, "position:y", plus_label.position.y - 40, plus_lifetime)
	
	# 渐隐动画
	tween.parallel().tween_property(plus_label, "modulate:a", 0.0, plus_lifetime)
	
	# 动画结束后删除+号（检查是否还存在）
	tween.finished.connect(func():
		if is_instance_valid(plus_label):
			plus_label.queue_free()
	)

# ============================================
# 持续时间结束
# ============================================
func _on_duration_timer_timeout():
	is_active = false
	
	# 停止+号定时器
	plus_timer.stop()
	
	# 清理所有剩余+号
	for child in get_children():
		if child is Label and is_instance_valid(child) and child != plus_timer and child != duration_timer:
			child.queue_free()
	
	# 延迟后删除自身
	await get_tree().create_timer(1.0).timeout
	queue_free()
