extends Node2D

# ============================================
# QuestMonsterSpawner.gd - Quest模式怪物生成器
# ============================================
# 特点：
# 1. 怪物从地图边缘生成（而非玩家周围）
# 2. 持续生成，直到达到总怪物数或等级上限
# 3. 生成后怪物在地图上随机游荡
# 4. 达到等级上限后停止生成
# ============================================

const MonsterDatabase = preload("res://Scripts/Monsters/monster_database.gd")

# 怪物场景映射
var monster_scenes := {
	"troll": preload("res://Scenes/Troll.tscn"),
	"spider": preload("res://Scenes/Spider.tscn"),
	"mummy": preload("res://Scenes/Mummy.tscn"),
	"demon": preload("res://Scenes/Demon.tscn"),
	"bear": preload("res://Scenes/Bear.tscn"),
	"reaper": preload("res://Scenes/Reaper.tscn"),
	"diablo": preload("res://Scenes/Diablo.tscn")
}

# 地图边界（怪物生成区域）
@export var map_width := 1536.0
@export var map_height := 1536.0
@export var spawn_margin := 100.0  # 边缘留出的空白区域

# 生成状态
var allowed_monsters := []
var is_spawning := false
var spawned_count := 0   # 已生成怪物数

# 生成间隔
@export var spawn_interval := 2.0  # 生成间隔（秒）
var spawn_timer := 0.0

# 引用
@onready var level_manager: Node = get_parent()

func _ready():
	add_to_group("monster_spawners")
	# 检查场景是否存在
	var to_remove := []
	for id in monster_scenes.keys():
		if monster_scenes[id] == null:
			push_warning("QuestMonsterSpawner: 场景未找到: " + id)
			to_remove.append(id)
	for id in to_remove:
		monster_scenes.erase(id)

func reset_spawner():
	"""读档时重置生成器状态"""
	allowed_monsters = []
	is_spawning = false
	spawned_count = 0
	spawn_timer = 0.0

func _process(delta):
	if not is_spawning:
		return
	
	# Quest模式：不再检查总怪物数，只检查是否被手动停止
	# 生成器会持续生成，直到达到经验上限时被 stop_spawning() 停止
	
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_monster_at_edge()

# ============================================
# 关卡控制
# ============================================

func start_level(config: Dictionary, skip_spawned: int = 0):
	"""开始新关卡
	
	参数:
		config: 关卡配置字典
		skip_spawned: 已生成的怪物数量（用于Resume Game）
	"""
	allowed_monsters = config["allowed_monsters"]
	spawned_count = skip_spawned
	is_spawning = true
	spawn_timer = spawn_interval  # 第一只立即生成
	
	print("QuestSpawner: 开始生成，允许怪物: %s" % str(allowed_monsters))

func stop_spawning():
	"""停止生成（达到等级上限时调用）"""
	is_spawning = false
	print("QuestSpawner: 停止刷怪")

func get_remaining_monsters() -> int:
	"""获取剩余需要生成的怪物数（Quest模式：返回-1表示无限）"""
	return -1  # 无限生成

# ============================================
# 怪物生成
# ============================================

func spawn_monster_at_edge():
	"""在地图边缘生成一只怪物"""
	if allowed_monsters.is_empty():
		push_error("QuestSpawner: 没有允许的怪物类型！")
		return
	
	# 随机选择怪物类型
	var monster_id = allowed_monsters[randi() % allowed_monsters.size()]
	
	# 检查场景
	if not monster_scenes.has(monster_id):
		push_error("QuestSpawner: 未知怪物ID: " + monster_id)
		return
	
	var scene = monster_scenes[monster_id]
	var monster = scene.instantiate()
	
	# 在地图边缘随机位置生成
	var spawn_pos = get_random_edge_position()
	monster.global_position = spawn_pos
	
	# 应用数据库数据
	var monster_data = MonsterDatabase.get_monster_data(
		monster_id,
		Global.hero_level,
		Global.current_difficulty,
		false  # Quest模式不是生存模式
	)
	
	if monster.has_method("apply_database_data"):
		monster.apply_database_data(monster_data)
	
	# 设置Quest模式行为（游荡）
	if monster.has_method("set_quest_mode"):
		monster.set_quest_mode(true)
	
	# 将怪物添加到场景根节点（QuestMain）
	var quest_main = get_tree().get_first_node_in_group("quest_main")
	if quest_main:
		quest_main.add_child(monster)
	else:
		get_parent().add_child(monster)
	
	# 增加生成计数
	spawned_count += 1
	
	# 通知关卡管理器
	if level_manager:
		level_manager.on_monster_spawned()
	
	# 连接死亡信号
	monster.tree_exited.connect(_on_monster_died)

func get_random_edge_position() -> Vector2:
	"""获取地图边缘的随机位置（确保不会卡在墙里）"""
	# 随机选择一条边：0=上, 1=右, 2=下, 3=左
	var side = randi() % 4
	var pos := Vector2.ZERO
	
	# 安全边界：确保生成在墙壁内侧
	var safe_min = spawn_margin
	var safe_max_x = map_width - spawn_margin
	var safe_max_y = map_height - spawn_margin
	
	match side:
		0:  # 上边
			pos.x = randf_range(safe_min, safe_max_x)
			pos.y = safe_min
		1:  # 右边
			pos.x = safe_max_x
			pos.y = randf_range(safe_min, safe_max_y)
		2:  # 下边
			pos.x = randf_range(safe_min, safe_max_x)
			pos.y = safe_max_y
		3:  # 左边
			pos.x = safe_min
			pos.y = randf_range(safe_min, safe_max_y)
	
	return pos

func _on_monster_died():
	"""怪物死亡时调用"""
	if level_manager:
		level_manager.on_monster_killed()
