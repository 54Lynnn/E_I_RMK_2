extends "res://Scripts/Monsters/monster_base.gd"

# ============================================
# MonsterMelee.gd - 近战怪物基类
# ============================================
# 所有近战怪物的父类。
# 提供通用的近战行为：发现玩家后追击，靠近后发动近战攻击。
#
# 继承这个类的怪物：
# - MonsterSpider (蜘蛛)
# - MonsterZombie (僵尸)
# - MonsterBear (熊)
# - MonsterDemon (恶魔)
# - MonsterReaper (死神)
# - MonsterBoss (Boss)
#
# 子类可以重写 _process_behavior() 来添加特殊行为。
# 如果只是想修改数值（速度、血量等），在 .tscn 中配置即可，不需要重写代码。
# ============================================

# ============================================
# _process_behavior(): 近战行为逻辑
# ============================================
# 这是近战怪物的标准行为：
# 1. 发现玩家 → 追击
# 2. 靠近玩家 → 停止移动（避免穿模）
# 3. 在攻击范围内 → 发动攻击
# 4. 玩家离开检测范围 → 停止追击
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
		
		# 【情况2】玩家太近（小于最小距离）
		elif dist <= min_distance:
			# 停止移动，避免贴脸穿模
			velocity = Vector2.ZERO
		
		# 【情况3】正常追击距离
		else:
			# 向玩家移动
			current_state = State.CHASE
			
			# 计算方向：从怪物指向玩家
			var dir = global_position.direction_to(target.global_position)
			
			# 设置速度
			velocity = dir * move_speed
			
			# 让怪物面向玩家（旋转贴图）
			sprite.rotation = atan2(dir.y, dir.x)
		
		# 【攻击判断】如果玩家在攻击范围内且冷却完毕
		if can_attack and dist <= attack_range:
			perform_attack()  # 发动近战攻击
	
	# 没有目标
	else:
		velocity = Vector2.ZERO
		current_state = State.IDLE
