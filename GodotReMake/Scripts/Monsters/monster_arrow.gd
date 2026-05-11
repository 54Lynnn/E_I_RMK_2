extends Area2D

# ============================================
# MonsterArrow.gd - 怪物弓箭/火焰投射物
# ============================================
# 这个脚本控制怪物发射的投射物（弓箭或火焰）。
# 投射物沿直线飞行，碰到玩家造成伤害后消失。
# 支持追踪效果（用于 Reaper 的火焰）。
#
# 创建方式：
# 由 monster_mummy.gd 或 monster_reaper.gd 在创建时设置属性
# ============================================

# ============================================
# 投射物属性
# ============================================
# 这些属性由创建者（Mummy 或 Reaper）在创建时设置

@export var speed := 300.0       # 飞行速度（像素/秒）
@export var damage := 6.0        # 伤害值：击中玩家时造成的伤害
@export var lifetime := 3.0      # 最大存活时间（秒）：防止内存泄漏
var direction := Vector2.RIGHT   # 飞行方向

# 【新增】追踪效果（用于 Reaper 的火焰）
var homing_target: Node2D = null  # 追踪目标（玩家）
var homing_strength := 0.0        # 追踪强度（度/秒），0 = 不追踪

# ============================================
# 内部变量
# ============================================
var _lifetime_timer := 0.0       # 存活计时器

# ============================================
# _ready(): 初始化
# ============================================
func _ready():
	# 连接碰撞信号：当弓箭碰到其他物体时触发 _on_body_entered
	body_entered.connect(_on_body_entered)
	
	# 设置自动销毁：lifetime 秒后自动消失
	# 这是安全措施，防止弓箭飞出地图后一直存在
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

# ============================================
# _process(): 每帧更新
# ============================================
# delta = 距离上一帧的时间（秒）
func _process(delta):
	# 【追踪效果】如果有追踪目标，逐渐转向目标
	if homing_target and homing_strength > 0:
		# 计算指向目标的方向
		var target_dir = global_position.direction_to(homing_target.global_position)
		
		# 计算当前方向与目标方向的夹角
		var current_angle = direction.angle()
		var target_angle = target_dir.angle()
		var angle_diff = wrapf(target_angle - current_angle, -PI, PI)
		
		# 限制每帧转向角度（避免瞬间转向）
		var max_turn = deg_to_rad(homing_strength) * delta
		angle_diff = clamp(angle_diff, -max_turn, max_turn)
		
		# 应用转向
		direction = direction.rotated(angle_diff)
	
	# 沿方向飞行
	position += direction * speed * delta
	
	# 【关键】让投射物贴图朝向飞行方向
	$Sprite2D.rotation = atan2(direction.y, direction.x)
	
	# 更新存活计时器
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()  # 销毁自己

# ============================================
# _on_body_entered(): 碰撞检测
# ============================================
# 当弓箭碰到其他物体时调用
func _on_body_entered(body: Node2D):
	# 检测是否碰到玩家（玩家属于 "hero" 分组）
	if body.is_in_group("hero"):
		# 对玩家造成伤害
		# 参数说明：
		# - damage: 伤害值
		# - false: 不是魔法伤害（是物理/基础伤害）
		# - null: 攻击者（这里不需要记录）
		Global.take_damage(damage, false, null)
		
		# 造成伤害后销毁弓箭
		queue_free()
