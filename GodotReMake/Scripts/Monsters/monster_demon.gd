extends "res://Scripts/Monsters/monster_melee.gd"

# ============================================
# MonsterDemon.gd - Blood Demon (血魔)
# ============================================
# 原版 Manual 描述：
# "Exceptional melee fighter. When demon starts to pursuit its speed increases by 40%."
#
# 特殊能力：
# - 【追击加速】当开始追击玩家时，速度增加40%
# - 火焰光环：靠近时持续受到火焰伤害（可选）
# ============================================

# 追击加速比例（原版：40%）
const PURSUIT_SPEED_BONUS := 1.4

# 是否正在追击
var is_pursuing := false

func _ready():
	# 设置怪物ID（必须在调用super._ready()之前）
	monster_id = "demon"
	
	# 调用父类的初始化（必须！）
	super._ready()

# ============================================
# _process_behavior(): 血魔行为逻辑
# ============================================
# 重写了父类的近战行为，添加了追击加速
func _process_behavior(delta):
	# 如果有目标（玩家）
	if target:
		# 计算与玩家的距离
		var dist = global_position.distance_to(target.global_position)
		
		# 【情况1】玩家太远（超出检测范围）
		if dist > detection_range:
			# 停止移动，进入待机状态
			velocity = Vector2.ZERO
			current_state = State.IDLE
			is_pursuing = false
			# 恢复原始速度
			move_speed = original_move_speed
		
		# 【情况2】玩家太近（小于最小距离）
		elif dist <= min_distance:
			# 停止移动，避免贴脸穿模
			velocity = Vector2.ZERO
			is_pursuing = false
			move_speed = original_move_speed
		
		# 【情况3】正常追击距离
		else:
			# 向玩家移动
			current_state = State.CHASE
			
			# 【特殊能力】追击加速
			if not is_pursuing:
				is_pursuing = true
				move_speed = original_move_speed * PURSUIT_SPEED_BONUS
			
			# 计算方向：从怪物指向玩家
			var dir = global_position.direction_to(target.global_position)
			
			# 设置速度
			velocity = dir * move_speed
			
			# 平滑转向面向玩家
			rotate_towards(dir, delta)
		
		# 【攻击判断】如果玩家在攻击范围内且冷却完毕
		if can_attack and dist <= attack_range:
			perform_attack()  # 发动近战攻击
	
	# 没有目标
	else:
		velocity = Vector2.ZERO
		current_state = State.IDLE
		is_pursuing = false
		move_speed = original_move_speed
