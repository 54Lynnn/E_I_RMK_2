extends Node2D

# ============================================
# MonsterSpawner.gd - 怪物生成器（通用）
# ============================================
# 所有模式（Quest/Survival）的怪物都从地图边缘生成
# 生成后怪物会随机游荡，发现玩家后追击
# ============================================

const MonsterDatabase = preload("res://Scripts/Monsters/monster_database.gd")

@export var spawn_interval := 1.0
@export var max_monsters := 15
@export var boss_spawn_chance := 0.05

# 地图边界（怪物生成区域）
@export var map_width := 2560.0
@export var map_height := 2560.0
@export var spawn_margin := 80.0  # 边缘留出的空白区域（避免卡在墙里）

var active_monsters := 0
var active_boss := false
var time_since_spawn := 0.0

# 怪物场景映射（ID -> 场景路径）
var monster_scenes := {
	"troll": preload("res://Scenes/Troll.tscn"),
	"spider": preload("res://Scenes/Spider.tscn"),
	"mummy": preload("res://Scenes/Mummy.tscn"),
	"demon": preload("res://Scenes/Demon.tscn"),
	"bear": preload("res://Scenes/Bear.tscn"),
	"reaper": preload("res://Scenes/Reaper.tscn"),
	"diablo": preload("res://Scenes/Diablo.tscn")
}

func _ready():
	# 检查场景是否存在
	var to_remove := []
	for id in monster_scenes.keys():
		if monster_scenes[id] == null:
			push_warning("MonsterSpawner: 场景未找到: " + id)
			to_remove.append(id)
	for id in to_remove:
		monster_scenes.erase(id)

func _process(delta):
	time_since_spawn += delta
	if time_since_spawn >= spawn_interval and active_monsters < max_monsters:
		time_since_spawn = 0.0
		spawn_monster()

func spawn_monster():
	var monster_id: String
	
	# 决定是否生成Diablo
	if not active_boss and randf() < boss_spawn_chance:
		monster_id = "diablo"
		active_boss = true
	else:
		# 根据玩家等级选择合适的怪物
		var suitable = MonsterDatabase.get_monsters_for_level(Global.hero_level)
		if suitable.is_empty():
			suitable = ["troll", "spider"]
		monster_id = suitable[randi() % suitable.size()]
	
	# 检查场景是否存在
	if not monster_scenes.has(monster_id):
		push_error("MonsterSpawner: 未知怪物ID: " + monster_id)
		return
	
	var scene = monster_scenes[monster_id]
	var monster = scene.instantiate()
	
	# 【从地图边缘生成】
	var spawn_pos = get_random_edge_position()
	monster.global_position = spawn_pos
	
	# 【关键】从数据库加载等级缩放后的数据
	var monster_data = MonsterDatabase.get_monster_data(
		monster_id,
		Global.hero_level,
		Global.current_difficulty,
		Global.current_game_mode == Global.GameMode.SURVIVAL
	)
	
	# 将数据应用到怪物实例
	if monster.has_method("apply_database_data"):
		monster.apply_database_data(monster_data)
	
	# 【启用游荡行为】所有模式的怪物都会游荡
	if monster.has_method("set_quest_mode"):
		monster.set_quest_mode(true)
	
	get_parent().add_child(monster)
	active_monsters += 1
	monster.tree_exited.connect(_on_monster_freed.bind(monster))

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

func _on_monster_freed(monster: Node):
	active_monsters -= 1
	if monster.name == "Diablo":
		active_boss = false
