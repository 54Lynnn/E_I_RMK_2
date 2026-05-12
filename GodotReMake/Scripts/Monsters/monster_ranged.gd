extends "res://Scripts/Monsters/monster_base.gd"

# ============================================
# MonsterRanged.gd - 远程怪物基类
# ============================================
# 所有远程怪物的父类（目前只有 Archer）。
# 提供通用的远程行为：保持距离，向玩家射箭。
#
# 继承这个类的怪物：
# - MonsterArcher (弓手)
#
# 远程怪物的特点：
# - 不会靠近玩家，而是保持一定距离
# - 攻击时有"前摇-发射-后摇"三个阶段
# - 玩家太靠近时会逃跑
#
# 子类可以重写 _process_behavior() 来添加特殊行为。
# ============================================

# ============================================
# 远程怪物特有属性
# ============================================
# 这些属性在 .tscn 场景中配置

@export var optimal_range := 250.0   # 最优攻击距离：在此距离内停止移动并攻击
@export var too_close_range := 150.0 # 逃跑距离：小于此距离会反向逃跑
@export var arrow_scene: PackedScene  # 弓箭场景：必须设置，否则无法射箭

# ============================================
# 攻击状态机变量
# ============================================
# 远程攻击不是瞬发的，而是有完整的攻击周期：
# 1. windup（前摇）：站定瞄准
# 2. fired（发射）：射出弓箭
# 3. recovery（后摇）：站定恢复

var is_attacking := false            # 是否正在攻击周期中？
var attack_phase := "none"           # 当前攻击阶段："windup"/"recovery"
var attack_timer := 0.0              # 攻击周期计时器（累加时间）

# 攻击时间常量（子类可以修改）
const ATTACK_WINDUP := 0.5           # 前摇时间：站定瞄准的时间
const ATTACK_RECOVERY := 1.5         # 后摇时间：发射后的硬直时间
const ARROW_SPEED := 300.0           # 弓箭飞行速度（像素/秒）
const ARROW_LIFETIME := 13.3         # 弓箭最大存活时间（秒），约4000像素飞行距离

# ============================================
# _process_behavior(): 远程行为逻辑
# ============================================
# 远程怪物有4种距离状态：
# 1. 太远 (> detection_range): 待机
# 2. 追击区 (optimal_range ~ detection_range): 向玩家移动
# 3. 攻击区 (too_close_range ~ optimal_range): 停止移动，射箭
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
	
	# 根据状态决定贴图朝向
	# 追击/攻击时：面向玩家
	# 逃跑时：背对玩家（转身逃跑），到达安全距离后再转回来
	
	# ============================================
	# 【攻击周期处理】
	# ============================================
	# 如果正在攻击周期中，处理前摇/后摇
	if is_attacking:
		_process_attack_cycle(delta)
		return  # 攻击周期中不处理距离判断
	
	# ============================================
	# 【距离判断与行为选择】
	# ============================================
	if dist > detection_range:
		# 【状态1：太远】玩家超出检测范围 → 停止移动，待机
		velocity = Vector2.ZERO
		current_state = State.IDLE
		# 待机时不旋转贴图，保持默认朝向（不面向玩家）
		
	elif dist <= too_close_range:
		# 【状态2：太近】玩家太靠近 → 逃跑（反向移动）
		current_state = State.CHASE
		var flee_dir = -dir_to_target  # 反向方向
		velocity = flee_dir * move_speed
		
		# 【转身效果】逃跑时平滑转向背对玩家
		rotate_towards(flee_dir, delta)
		
		# 如果正在攻击中，取消攻击（被打断）
		_cancel_attack()
		
	elif dist <= optimal_range:
		# 【状态3：攻击区】在 optimal_range 内 → 停止移动，开始攻击
		velocity = Vector2.ZERO
		current_state = State.ATTACK
		# 攻击时平滑转向面向玩家（瞄准）
		rotate_towards(dir_to_target, delta)
		
		# 如果冷却完毕，开始新的攻击周期
		if can_attack:
			_start_attack()
		
	else:
		# 【状态4：追击区】在 optimal_range 和 detection_range 之间 → 追击
		current_state = State.CHASE
		velocity = dir_to_target * move_speed
		# 追击时平滑转向面向玩家
		rotate_towards(dir_to_target, delta)

# ============================================
# 处理攻击周期
# ============================================
# 处理前摇和后摇阶段
func _process_attack_cycle(delta):
	attack_timer += delta  # 累加时间
	
	if attack_phase == "windup":
		# 【前摇阶段】站定瞄准，不能移动
		velocity = Vector2.ZERO
		current_state = State.ATTACK
		
		# 前摇时间到，发射弓箭
		if attack_timer >= ATTACK_WINDUP:
			_fire_arrow()           # 发射！
			attack_phase = "recovery"  # 进入后摇阶段
			attack_timer = 0.0         # 重置计时器
			
	elif attack_phase == "recovery":
		# 【后摇阶段】站定恢复，不能移动
		velocity = Vector2.ZERO
		current_state = State.ATTACK
		
		# 后摇时间到，攻击周期结束
		if attack_timer >= ATTACK_RECOVERY:
			is_attacking = false    # 攻击结束
			attack_phase = "none"   # 重置阶段
			can_attack = true       # 可以开始下一次攻击

# ============================================
# 开始攻击
# ============================================
# 进入攻击周期的前摇阶段
func _start_attack():
	is_attacking = true        # 进入攻击周期
	attack_phase = "windup"    # 进入前摇阶段
	attack_timer = 0.0         # 重置计时器
	can_attack = false         # 开始冷却

# ============================================
# 取消攻击
# ============================================
# 当玩家太靠近时，取消当前的攻击
func _cancel_attack():
	if is_attacking:
		is_attacking = false
		attack_phase = "none"
		can_attack = true

# ============================================
# 发射弓箭
# ============================================
# 在前摇结束时调用，创建弓箭投射物
func _fire_arrow():
	# 安全检查：确保有目标和弓箭场景
	if not target or not arrow_scene:
		return
	
	# 创建弓箭实例
	var arrow = arrow_scene.instantiate()
	arrow.name = "monster_arrow"
	arrow.global_position = global_position  # 从怪物位置发射
	
	# 计算发射方向：指向玩家，±15度随机偏移
	var base_dir = global_position.direction_to(target.global_position)
	var angle_offset = deg_to_rad(randf() * 30.0 - 15.0)  # -15到+15度随机
	var arrow_dir = base_dir.rotated(angle_offset)
	
	# 设置弓箭属性
	arrow.direction = arrow_dir
	arrow.speed = ARROW_SPEED
	arrow.damage = damage          # 使用怪物的 damage 属性作为弓箭伤害
	arrow.lifetime = ARROW_LIFETIME
	
	# 将弓箭添加到场景中（不是添加到怪物内部，否则弓箭会跟着怪物移动）
	get_parent().add_child(arrow)
