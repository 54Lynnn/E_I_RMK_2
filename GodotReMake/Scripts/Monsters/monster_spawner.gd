extends Node2D

const MonsterDatabase = preload("res://Scripts/Monsters/monster_database.gd")

enum SpawnPattern { SINGLE, LINE, GROUP, ALL_SIDES, HORDE }

@export var map_width := 1536.0
@export var map_height := 1536.0
@export var spawn_margin := 10.0

var active_monsters := 0
var diablo_monsters := []

# 四种生成模式的定时器
var timer_target_single := 0.0
var timer_target_line := 0.0
var timer_target_group := 0.0
var timer_target_all_sides := 0.0

# HORDE 兽群模式状态
var timer_target_horde := 0.0
var horde_active := false
var horde_elapsed := 0.0
var horde_duration := 5.0
var horde_monster_id := ""
var horde_spawn_timer := 0.0
const HORDE_SPAWN_INTERVAL := 0.5

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
	add_to_group("monster_spawners")
	var to_remove := []
	for id in monster_scenes.keys():
		if monster_scenes[id] == null:
			push_warning("MonsterSpawner: 场景未找到: " + id)
			to_remove.append(id)
	for id in to_remove:
		monster_scenes.erase(id)
	_set_new_timer_targets()

func _set_new_timer_targets():
	timer_target_single = _get_single_interval()
	timer_target_line = _get_line_interval()
	timer_target_group = _get_group_interval()
	timer_target_all_sides = _get_all_sides_interval()
	timer_target_horde = _get_horde_interval()

func _get_single_interval() -> float:
	var avg = max(0.3, 2.0 - (Global.hero_level - 1) * 0.05)
	return randf_range(avg * 0.5, avg * 1.5)

func _get_group_interval() -> float:
	var reduction = min(3.9, (Global.hero_level - 1) * 0.1)
	return randf_range(max(4.0, 8.0 - reduction), max(8.0, 12.0 - reduction))

func _get_line_interval() -> float:
	var reduction = min(3.9, (Global.hero_level - 1) * 0.1)
	return randf_range(max(14.0, 18.0 - reduction), max(18.0, 22.0 - reduction))

func _get_all_sides_interval() -> float:
	var effective = max(0, Global.hero_level - 9)
	var reduction = min(6.2, effective * 0.2)
	return randf_range(max(32.0, 38.0 - reduction), max(36.0, 42.0 - reduction))

func _get_horde_interval() -> float:
	var effective = max(0, Global.hero_level - 15)
	var reduction = min(5.0, effective * 0.2)
	return randf_range(max(23.0, 28.0 - reduction), max(27.0, 32.0 - reduction))

func _get_center_direction(from_pos: Vector2) -> Vector2:
	var center = Vector2(map_width * 0.5, map_height * 0.5)
	var to_center = (center - from_pos).normalized()
	var angle_offset = deg_to_rad(randf_range(-60, 60))
	return to_center.rotated(angle_offset)

func _process(delta):
	timer_target_single -= delta
	if timer_target_single <= 0:
		timer_target_single = _get_single_interval()
		_spawn_pattern(SpawnPattern.SINGLE)

	timer_target_line -= delta
	if timer_target_line <= 0:
		timer_target_line = _get_line_interval()
		_spawn_pattern(SpawnPattern.LINE)

	timer_target_group -= delta
	if timer_target_group <= 0:
		timer_target_group = _get_group_interval()
		_spawn_pattern(SpawnPattern.GROUP)

	var all_sides_unlocked := true
	if Global.current_game_mode == Global.GameMode.QUEST and Global.hero_level < 17:
		all_sides_unlocked = false
	if all_sides_unlocked and Global.hero_level >= 9:
		timer_target_all_sides -= delta
		if timer_target_all_sides <= 0:
			timer_target_all_sides = _get_all_sides_interval()
			_spawn_pattern(SpawnPattern.ALL_SIDES)

	if Global.hero_level >= 15:
		if horde_active:
			horde_elapsed += delta
			if horde_elapsed >= horde_duration:
				horde_active = false
				timer_target_horde = _get_horde_interval()
			else:
				horde_spawn_timer += delta
				if horde_spawn_timer >= HORDE_SPAWN_INTERVAL:
					horde_spawn_timer = 0.0
					_spawn_horde_batch()
		else:
			timer_target_horde -= delta
			if timer_target_horde <= 0:
				_spawn_pattern(SpawnPattern.HORDE)

func _spawn_pattern(pattern: SpawnPattern):
	match pattern:
		SpawnPattern.SINGLE:
			_spawn_single()
		SpawnPattern.LINE:
			_spawn_line()
		SpawnPattern.GROUP:
			_spawn_group()
		SpawnPattern.ALL_SIDES:
			_spawn_all_sides()
		SpawnPattern.HORDE:
			_spawn_horde()

func _create_monster(monster_id: String, spawn_pos: Vector2, wander_dir: Vector2) -> bool:
	if not monster_scenes.has(monster_id):
		return false
	if monster_id == "diablo" and diablo_monsters.size() >= 3:
		return false

	var scene = monster_scenes[monster_id]
	var monster = scene.instantiate()
	monster.global_position = spawn_pos

	var monster_data = MonsterDatabase.get_monster_data(
		monster_id, Global.hero_level,
		Global.current_difficulty,
		Global.current_game_mode == Global.GameMode.SURVIVAL
	)
	if monster.has_method("apply_database_data"):
		monster.apply_database_data(monster_data)
	if monster.has_method("set_quest_mode"):
		monster.set_quest_mode(true)

	get_parent().add_child(monster)

	monster.modulate.a = 0.0
	var fade_tween = monster.create_tween()
	fade_tween.tween_property(monster, "modulate:a", 1.0, 0.5)

	if monster.has_method("set_wander_direction"):
		monster.set_wander_direction(wander_dir)
	active_monsters += 1
	if monster_id == "diablo":
		diablo_monsters.append(monster)
		monster.tree_exited.connect(_on_diablo_freed.bind(monster))
	else:
		monster.tree_exited.connect(_on_monster_freed)
	return true

func _on_monster_freed():
	if active_monsters > 0:
		active_monsters -= 1

func _on_diablo_freed(diablo: Node):
	if active_monsters > 0:
		active_monsters -= 1
	diablo_monsters.erase(diablo)

func _spawn_single():
	var monster_id = MonsterDatabase.pick_monster_for_level(Global.hero_level)
	var spawn_pos = get_random_edge_position()
	var wander_dir = _get_center_direction(spawn_pos)
	_create_monster(monster_id, spawn_pos, wander_dir)

func _spawn_line():
	var exclude_list = ["reaper", "diablo"]
	var monster_id = MonsterDatabase.pick_monster_for_level(Global.hero_level, exclude_list)
	var side = randi() % 4
	var count = 15

	var edge_positions := _get_edge_line_positions(side, count)
	var wander_dir := _get_edge_wander_direction(side)

	for pos in edge_positions:
		_create_monster(monster_id, pos, wander_dir)

func _spawn_group():
	var exclude_list = ["diablo"]
	var monster_id = MonsterDatabase.pick_monster_for_level(Global.hero_level, exclude_list)
	var side = randi() % 4
	var roll = randi() % 6
	var grid_size: Array
	if roll < 1:
		grid_size = [3, 3]
	elif roll < 3:
		grid_size = [3, 2]
	else:
		grid_size = [2, 2]
	var cols = grid_size[0]
	var rows = grid_size[1]

	var anchor = get_random_edge_position()

	var layout_dir := Vector2.ZERO
	match side:
		0: layout_dir = Vector2(0, 1)
		1: layout_dir = Vector2(-1, 0)
		2: layout_dir = Vector2(0, -1)
		3: layout_dir = Vector2(1, 0)

	var spawn_dir = _get_center_direction(anchor)

	var spacing := 40.0
	for row in range(rows):
		for col in range(cols):
			var offset = Vector2(col * spacing, row * spacing)
			var rotated_offset = Vector2(
				offset.x * abs(layout_dir.y) + offset.y * abs(layout_dir.x),
				offset.y * abs(layout_dir.y) + offset.x * abs(layout_dir.x)
			)
			var pos = anchor + rotated_offset
			pos.x = clamp(pos.x, spawn_margin, map_width - spawn_margin)
			pos.y = clamp(pos.y, spawn_margin, map_height - spawn_margin)
			_create_monster(monster_id, pos, spawn_dir)

func _spawn_all_sides():
	var exclude_list = ["reaper", "diablo"]
	var monster_id = MonsterDatabase.pick_monster_for_level(Global.hero_level, exclude_list)
	var per_side := 12

	for side in range(4):
		var edge_positions := _get_edge_line_positions(side, per_side)
		var wander_dir := _get_edge_wander_direction(side)
		for pos in edge_positions:
			_create_monster(monster_id, pos, wander_dir)

func _spawn_horde():
	var exclude_list = ["reaper", "diablo"]
	horde_monster_id = MonsterDatabase.pick_monster_for_level(Global.hero_level, exclude_list)
	horde_active = true
	horde_elapsed = 0.0
	horde_spawn_timer = 0.0
	var extra_duration = floor(max(0, Global.hero_level - 15) / 10) * 1.0
	horde_duration = 5.0 + extra_duration

func _spawn_horde_batch():
	var corners = [
		Vector2(spawn_margin, spawn_margin),
		Vector2(map_width - spawn_margin, spawn_margin),
		Vector2(spawn_margin, map_height - spawn_margin),
		Vector2(map_width - spawn_margin, map_height - spawn_margin)
	]
	var center = Vector2(map_width * 0.5, map_height * 0.5)
	for corner in corners:
		var dir = (center - corner).normalized()
		_create_monster(horde_monster_id, corner, dir)

func get_random_edge_position() -> Vector2:
	var side = randi() % 4
	var pos := Vector2.ZERO
	var safe_min = spawn_margin
	var safe_max_x = map_width - spawn_margin
	var safe_max_y = map_height - spawn_margin

	match side:
		0:
			pos.x = randf_range(safe_min, safe_max_x)
			pos.y = safe_min
		1:
			pos.x = safe_max_x
			pos.y = randf_range(safe_min, safe_max_y)
		2:
			pos.x = randf_range(safe_min, safe_max_x)
			pos.y = safe_max_y
		3:
			pos.x = safe_min
			pos.y = randf_range(safe_min, safe_max_y)
	return pos

func _get_edge_line_positions(side: int, count: int) -> Array:
	var positions := []
	var spacing := 0.0
	var start := 0.0

	match side:
		0, 2:
			var usable = map_width - spawn_margin * 2
			spacing = usable / (count + 1)
			start = spawn_margin + spacing
			for i in range(count):
				var x = start + spacing * i
				var y = spawn_margin if side == 0 else map_height - spawn_margin
				positions.append(Vector2(x, y))
		1, 3:
			var usable = map_height - spawn_margin * 2
			spacing = usable / (count + 1)
			start = spawn_margin + spacing
			for i in range(count):
				var x = map_width - spawn_margin if side == 1 else spawn_margin
				var y = start + spacing * i
				positions.append(Vector2(x, y))
	return positions

func _get_edge_wander_direction(side: int) -> Vector2:
	match side:
		0: return Vector2.DOWN
		1: return Vector2.LEFT
		2: return Vector2.UP
		3: return Vector2.RIGHT
		_: return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func reset_spawner():
	active_monsters = 0
	diablo_monsters.clear()
	horde_active = false
	_set_new_timer_targets()
