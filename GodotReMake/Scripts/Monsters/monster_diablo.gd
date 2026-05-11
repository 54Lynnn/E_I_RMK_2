extends "res://Scripts/Monsters/monster_base.gd"

# ============================================
# MonsterDiablo.gd - Diablo (暗黑破坏神)
# ============================================
# 原版 Manual 描述：
# "Diablo does not fight with the hero himself. Instead of this, Diablo summons
#  different monsters around the hero."
#
# 召唤概率：
# - 5% Reapers
# - 10% Blood Demons
# - 15% Bears
# - 20% Mummies
# - 25% Spiders
# - 25% Trolls
#
# 行为特点：
# - 不直接攻击玩家
# - 保持距离，避免近战
# - 每5秒召唤一次怪物
# - 召唤位置在 Diablo 的上下左右100px方位
# - 玩家太靠近时会后退
# ============================================

# ============================================
# 召唤系统常量
# ============================================
const SUMMON_COOLDOWN := 5.0         # 召唤冷却时间（秒）
const SUMMON_COUNT := 4              # 每次召唤数量
const SUMMON_OFFSET := 100.0         # 召唤位置偏移（上下左右100px）
const OPTIMAL_RANGE := 300.0         # 最优距离：保持这个距离召唤
const TOO_CLOSE_RANGE := 200.0       # 逃跑距离：小于此距离会后退

# ============================================
# 召唤概率表（按 Manual 设定）
# ============================================
const SUMMON_TABLE := {
	"reaper": 0.05,    # 5%
	"demon": 0.10,     # 10%
	"bear": 0.15,      # 15%
	"mummy": 0.20,     # 20%
	"spider": 0.25,    # 25%
	"troll": 0.25      # 25%
}

# ============================================
# 运行时变量
# ============================================
var can_summon := true               # 是否可以召唤
var summon_timer: Timer = null       # 召唤计时器

func _ready():
	# 设置怪物ID
	monster_id = "diablo"
	
	# 调用父类初始化
	super._ready()
	
	# 创建召唤计时器
	summon_timer = Timer.new()
	summon_timer.wait_time = SUMMON_COOLDOWN
	summon_timer.one_shot = true
	summon_timer.timeout.connect(_on_summon_cooldown_timeout)
	add_child(summon_timer)

# ============================================
# _process_behavior(): Diablo 行为逻辑
# ============================================
# Diablo 不直接攻击，而是保持距离并召唤怪物
func _process_behavior(delta):
	if target:
		var dist = global_position.distance_to(target.global_position)
		var dir_to_target = global_position.direction_to(target.global_position)
		
		# 【行为1】玩家太远 - 停止移动
		if dist > detection_range:
			velocity = Vector2.ZERO
			current_state = State.IDLE
		
		# 【行为2】玩家太近 - 逃跑保持最远距离
		elif dist < TOO_CLOSE_RANGE:
			current_state = State.CHASE
			# 远离玩家的方向
			var flee_dir = -dir_to_target
			velocity = flee_dir * move_speed
			sprite.rotation = atan2(flee_dir.y, flee_dir.x)
		
		# 【行为3】理想距离 - 停止移动，尝试召唤
		else:
			velocity = Vector2.ZERO
			current_state = State.IDLE
			sprite.rotation = atan2(dir_to_target.y, dir_to_target.x)
			
			# 尝试召唤怪物
			if can_summon:
				perform_summon()
	else:
		velocity = Vector2.ZERO
		current_state = State.IDLE

# ============================================
# 召唤怪物
# ============================================
func perform_summon():
	if not target:
		return
	
	can_summon = false
	summon_timer.start()
	
	# 召唤4个怪物
	for i in range(SUMMON_COUNT):
		# 根据概率选择怪物类型
		var selected_monster = _select_monster_by_probability()
		
		# 获取怪物场景路径
		var scene_path = _get_monster_scene_path(selected_monster)
		if scene_path.is_empty():
			continue
		
		var scene = load(scene_path)
		if not scene:
			continue
		
		var monster = scene.instantiate()
		
		# 计算召唤位置（Diablo的上下左右100px）
		var spawn_pos = _get_summon_position(i)
		monster.global_position = spawn_pos
		
		# 从数据库加载数据
		var monster_data = MonsterDatabase.get_monster_data(
			selected_monster,
			Global.hero_level,
			Global.current_difficulty,
			Global.current_game_mode == Global.GameMode.SURVIVAL
		)
		
		if monster.has_method("apply_database_data"):
			monster.apply_database_data(monster_data)
		
		# 添加到场景
		get_parent().add_child(monster)

# ============================================
# 根据概率选择怪物
# ============================================
func _select_monster_by_probability() -> String:
	var roll = randf()
	var cumulative := 0.0
	
	for monster_id in SUMMON_TABLE.keys():
		cumulative += SUMMON_TABLE[monster_id]
		if roll <= cumulative:
			return monster_id
	
	# 默认返回 troll（以防万一）
	return "troll"

# ============================================
# 获取召唤位置
# ============================================
# 根据索引i，返回Diablo周围的4个位置之一：
# i=0: 上方, i=1: 右方, i=2: 下方, i=3: 左方
func _get_summon_position(index: int) -> Vector2:
	match index:
		0: return global_position + Vector2(0, -SUMMON_OFFSET)  # 上方
		1: return global_position + Vector2(SUMMON_OFFSET, 0)   # 右方
		2: return global_position + Vector2(0, SUMMON_OFFSET)   # 下方
		3: return global_position + Vector2(-SUMMON_OFFSET, 0)  # 左方
		_: return global_position + Vector2(randf() * 200 - 100, randf() * 200 - 100)

# ============================================
# 获取怪物场景路径
# ============================================
func _get_monster_scene_path(monster_id: String) -> String:
	match monster_id:
		"troll": return "res://Scenes/Troll.tscn"
		"spider": return "res://Scenes/Spider.tscn"
		"mummy": return "res://Scenes/Mummy.tscn"
		"demon": return "res://Scenes/Demon.tscn"
		"bear": return "res://Scenes/Bear.tscn"
		"reaper": return "res://Scenes/Reaper.tscn"
		_: return ""

# ============================================
# 召唤冷却结束
# ============================================
func _on_summon_cooldown_timeout():
	can_summon = true
