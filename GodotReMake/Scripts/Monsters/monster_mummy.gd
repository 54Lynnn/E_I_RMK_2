extends "res://Scripts/Monsters/monster_ranged.gd"

# ============================================
# MonsterMummy.gd - 木乃伊怪物（Mummy）
# ============================================
# 远程怪物，使用弓箭攻击玩家。
#
# 行为特点：
# - 保持与玩家的距离
# - 在 optimal_range 内停止移动并射箭
# - 玩家太靠近时（< too_close_range）会逃跑
# - 攻击时有"前摇-发射-后摇"三个阶段，共2秒
#
# 继承关系：
#   MonsterBase -> MonsterRanged -> MonsterMummy
# ============================================

func _ready():
	# 设置怪物ID（必须在调用super._ready()之前）
	monster_id = "mummy"
	
	# 调用父类的初始化（必须！）
	# 父类 _ready() 会设置血条、计时器等基础功能
	super._ready()
	
	# Archer特有的初始化
	# 例如：初始化箭袋数量、特殊箭矢类型等

# ============================================
# _process_behavior(): Archer行为逻辑
# ============================================
# 目前使用父类（MonsterRanged）的标准远程行为。
#
# 如果要添加特殊行为（如连射、特殊箭矢等），重写这个方法：
#
# func _process_behavior(delta):
#     # 调用父类行为（保持距离+射箭）
#     super._process_behavior(delta)
#
#     # 添加 Archer 特有逻辑
#     # 例如：血量低于50%时逃跑速度加倍
#     # if health < max_health * 0.5:
#     #     move_speed = original_move_speed * 1.5
