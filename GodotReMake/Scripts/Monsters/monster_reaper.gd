extends "res://Scripts/Monsters/monster_base.gd"

# ============================================
# MonsterReaper.gd - Reaper (死神)
# ============================================
# 原版 Manual 描述：
# "Strong warrior with magic range attack. Attacks with 3 flames."
#
# 行为特点：
# - 远程攻击：发射3个火焰弹
# - 火焰有微弱追踪效果（自动转向玩家）
# - 玩家太靠近时会后退（类似Mummy）
# - 攻击间隔较长（5秒）
#
# 继承关系：
#   MonsterBase -> MonsterReaper
# ============================================

# ============================================
# 远程攻击属性
# ============================================
@export var optimal_range := 250.0   # 最优攻击距离：在此距离内停止移动并攻击
@export var too_close_range := 150.0 # 逃跑距离：小于此距离会反向逃跑
@export var flame_scene: PackedScene  # 火焰场景：必须设置，否则无法发射

# ============================================
# 攻击状态机变量
# ============================================
var is_attacking := false            # 是否正在攻击周期中？
var attack_phase := "none"           # 当前攻击阶段："windup"/"recovery"
var attack_timer := 0.0              # 攻击周期计时器
var flames_fired := 0                # 已发射的火焰数量

# 攻击时间常量
const ATTACK_WINDUP := 0.5           # 前摇时间：站定瞄准
const ATTACK_RECOVERY := 1.5         # 后摇时间：发射后的硬直
const FLAME_INTERVAL := 0.15         # 3个火焰之间的发射间隔
const FLAME_SPEED := 250.0           # 火焰飞行速度（像素/秒）
const FLAME_LIFETIME := 5.0          # 火焰最大存活时间（秒）
const FLAME_HOMING_STRENGTH := 2.0   # 追踪强度：每秒转向玩家的角度（度）

func _ready():
	# 设置怪物ID（必须在调用super._ready()之前）
	monster_id = "reaper"
	
	# 调用父类的初始化（必须！）
	super._ready()
	
	# 如果没有设置火焰场景，使用默认的
	if not flame_scene:
		flame_scene = preload("res://Scenes/MonsterArrow.tscn")

# ============================================
# _process_behavior(): Reaper 行为逻辑
# ============================================
# Reaper 有4种距离状态：
# 1. 太远 (> detection_range): 待机
# 2. 追击区 (optimal_range ~ detection_range): 向玩家移动
# 3. 攻击区 (too_close_range ~ optimal_range): 停止移动，发射火焰
# 4. 逃跑区 (< too_close_range): 反向逃跑
func _process_behavior(delta):
	# 没有目标：停止移动
	if not target:
		velocity = Vector2.ZERO
		current_state = State.IDLE
		return
	
	# 计算与玩家的距离和方向
	var dist = global_position.distance_to(target.global_position)
	var dir_to_target = global_position.direction_to(target.global_position)
	
	# ============================================
	# 【攻击周期处理】
	# ============================================
	if is_attacking:
		_process_attack_cycle(delta)
		return
	
	# ============================================
	# 【距离判断与行为选择】
	# ============================================
	if dist > detection_range:
		# 【状态1：太远】玩家超出检测范围 → 停止移动，待机
		velocity = Vector2.ZERO
		current_state = State.IDLE
		
	elif dist <= too_close_range:
		# 【状态2：太近】玩家太靠近 → 逃跑（反向移动）
		current_state = State.CHASE
		var flee_dir = -dir_to_target
		velocity = flee_dir * move_speed
		rotate_towards(flee_dir, delta)
		
		# 如果正在攻击中，取消攻击（被打断）
		_cancel_attack()
		
	elif dist <= optimal_range:
		# 【状态3：攻击区】在 optimal_range 内 → 停止移动，开始攻击
		velocity = Vector2.ZERO
		current_state = State.ATTACK
		rotate_towards(dir_to_target, delta)
		
		# 如果冷却完毕，开始新的攻击周期
		if can_attack:
			_start_attack()
		
	else:
		# 【状态4：追击区】在 optimal_range 和 detection_range 之间 → 追击
		current_state = State.CHASE
		velocity = dir_to_target * move_speed
		rotate_towards(dir_to_target, delta)

# ============================================
# 处理攻击周期
# ============================================
func _process_attack_cycle(delta):
	attack_timer += delta
	
	if attack_phase == "windup":
		# 【前摇阶段】站定瞄准
		velocity = Vector2.ZERO
		current_state = State.ATTACK
		if target:
			rotate_towards(global_position.direction_to(target.global_position), delta)
		
		# 前摇时间到，开始发射3个火焰
		if attack_timer >= ATTACK_WINDUP:
			flames_fired = 0
			attack_phase = "firing"
			attack_timer = 0.0
			
	elif attack_phase == "firing":
		# 【发射阶段】依次发射3个火焰
		velocity = Vector2.ZERO
		current_state = State.ATTACK
		
		# 每隔 FLAME_INTERVAL 发射一个火焰
		if attack_timer >= flames_fired * FLAME_INTERVAL:
			_fire_flame()
			flames_fired += 1
			
			# 3个火焰都发射完毕，进入后摇
			if flames_fired >= 3:
				attack_phase = "recovery"
				attack_timer = 0.0
			
	elif attack_phase == "recovery":
		# 【后摇阶段】站定恢复
		velocity = Vector2.ZERO
		current_state = State.ATTACK
		
		# 后摇时间到，攻击周期结束
		if attack_timer >= ATTACK_RECOVERY:
			is_attacking = false
			attack_phase = "none"
			can_attack = true

# ============================================
# 开始攻击
# ============================================
func _start_attack():
	is_attacking = true
	attack_phase = "windup"
	attack_timer = 0.0
	flames_fired = 0
	can_attack = false

# ============================================
# 取消攻击
# ============================================
func _cancel_attack():
	if is_attacking:
		is_attacking = false
		attack_phase = "none"
		can_attack = true

# ============================================
# 发射火焰
# ============================================
func _fire_flame():
	# 安全检查
	if not target or not flame_scene:
		return
	
	# 创建火焰实例
	var flame = ObjectPool.get_object(flame_scene)
	flame.name = "reaper_flame"
	flame.global_position = global_position
	
	# 计算发射方向：指向玩家，±20度随机散布
	var base_dir = global_position.direction_to(target.global_position)
	var angle_offset = deg_to_rad(randf() * 40.0 - 20.0)  # -20到+20度随机
	var flame_dir = base_dir.rotated(angle_offset)
	
	# 设置火焰属性
	flame.direction = flame_dir
	flame.speed = FLAME_SPEED
	flame.damage = damage
	flame.lifetime = FLAME_LIFETIME
	
	# 【关键】启用追踪效果
	flame.homing_target = target
	flame.homing_strength = FLAME_HOMING_STRENGTH
	
	# 将火焰添加到场景中
	get_parent().add_child(flame)
