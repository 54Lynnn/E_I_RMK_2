extends CharacterBody2D

# ============================================
# Hero.gd - 玩家英雄控制器
# ============================================
# 这个文件控制玩家角色的所有行为，包括：
# 1. 移动控制（WASD）
# 2. 技能施放（调用各技能脚本的 cast 方法）
# 3. 鼠标瞄准（角色朝向鼠标）
# 4. 碰撞检测（与怪物碰撞）
# 5. 冷却时间管理（维护 skill_cooldowns 字典）
#
# 节点结构（在Hero.tscn中定义）：
# - Sprite2D: 角色精灵图
#   - Muzzle: 发射口（技能从这里发射）
# - CastCooldown: 计时器（控制技能冷却）
# - LevelLabel: 头顶等级标签
#
# 技能施放流程：
# 1. 检测按键输入 -> _unhandled_input()
# 2. 调用对应技能的 SkillScript.cast(self, mouse_pos, skill_cooldowns)
# 3. 技能脚本内部处理：检查等级、冷却、法力、创建效果、设置冷却
# ============================================

# 导入已重构的技能脚本
const MagicMissile = preload("res://Scripts/Spells/magic_missile.gd")
const Fireball = preload("res://Scripts/Spells/fireball.gd")
const FreezingSpear = preload("res://Scripts/Spells/freezing_spear.gd")
const Prayer = preload("res://Scripts/Spells/prayer.gd")
const Heal = preload("res://Scripts/Spells/heal.gd")
const Teleport = preload("res://Scripts/Spells/teleport.gd")
const MistFog = preload("res://Scripts/Spells/mistfog.gd")
const StoneEnchanted = preload("res://Scripts/Spells/stone_enchanted.gd")
const WrathOfGod = preload("res://Scripts/Spells/wrath_of_god.gd")
const Telekinesis = preload("res://Scripts/Spells/telekinesis.gd")
const Sacrifice = preload("res://Scripts/Spells/sacrifice.gd")
const HolyLight = preload("res://Scripts/Spells/holy_light.gd")
const FireWalk = preload("res://Scripts/Spells/fire_walk.gd")
const Meteor = preload("res://Scripts/Spells/meteor.gd")
const Armageddon = preload("res://Scripts/Spells/armageddon.gd")
const PoisonCloud = preload("res://Scripts/Spells/poison_cloud.gd")
const Fortuna = preload("res://Scripts/Spells/fortuna.gd")
const DarkRitual = preload("res://Scripts/Spells/dark_ritual.gd")
const Nova = preload("res://Scripts/Spells/nova.gd")
const BallLightning = preload("res://Scripts/Spells/ball_lightning.gd")
const ChainLightning = preload("res://Scripts/Spells/chain_lightning.gd")

# 技能脚本字典（用于统一施法调度）
const SKILL_SCRIPTS := {
	"magic_missile": MagicMissile,
	"fireball": Fireball,
	"freezing_spear": FreezingSpear,
	"prayer": Prayer,
	"heal": Heal,
	"teleport": Teleport,
	"mistfog": MistFog,
	"stone_enchanted": StoneEnchanted,
	"wrath_of_god": WrathOfGod,
	"telekinesis": Telekinesis,
	"sacrifice": Sacrifice,
	"holy_light": HolyLight,
	"fire_walk": FireWalk,
	"meteor": Meteor,
	"armageddon": Armageddon,
	"poison_cloud": PoisonCloud,
	"fortuna": Fortuna,
	"dark_ritual": DarkRitual,
	"nova": Nova,
	"ball_lightning": BallLightning,
	"chain_lightning": ChainLightning,
}

const SKILLS_NO_ATTACK := {
	"teleport": true,
	"telekinesis": true,
	"fortuna": true,
}

const SKILLS_NO_MULTICAST := {
	"fire_walk": true,
}

# 基础移动速度（像素/秒）
# 原版公式：DEXTERITY_ON_SPEED = 0.5, START_VALUE = 65
const BASE_MOVE_SPEED := 65.0

# 加速度和摩擦力（用于平滑移动）
# 值越大，角色启动和停止越快
@export var acceleration := 3000.0
@export var friction := 3000.0

# @onready 表示在节点_ready()时自动获取这些子节点
@onready var sprite := $Sprite2D          # 角色精灵图
@onready var muzzle := $Sprite2D/Muzzle   # 技能发射位置
@onready var cast_cooldown := $CastCooldown  # 技能冷却计时器

# 变量声明
var mouse_pos := Vector2.ZERO   # 鼠标在世界中的位置

# 技能独立冷却系统（每个技能有自己的冷却状态）
var skill_cooldowns := {
	"magic_missile": 0.0,
	"fireball": 0.0,
	"freezing_spear": 0.0,
	"prayer": 0.0,
	"teleport": 0.0,
	"mistfog": 0.0,
	"wrath_of_god": 0.0,
	"telekinesis": 0.0,
	"sacrifice": 0.0,
	"holy_light": 0.0,
	"stone_enchanted": 0.0,
	"heal": 0.0,
	"fire_walk": 0.0,
	"meteor": 0.0,
	"armageddon": 0.0,
	"poison_cloud": 0.0,
	"fortuna": 0.0,
	"dark_ritual": 0.0,
	"nova": 0.0,
	"ball_lightning": 0.0,
	"chain_lightning": 0.0,
}

# 技能状态标记
var prayer_active := false      # 祈祷技能是否激活

# 注意：受击减速现在通过 Global 的 buff 系统管理
# debuff ID: "hit_slow"
# 原版：被怪物攻击后减速20%，持续0.5秒

# 受击恢复系统（hit recovery）
# 原版：被攻击后一段时间内不能施法，移动速度降低
var hit_recovery_timer := 0.0   # 受击恢复剩余时间

# 行走动画
var walk_frame := 0             # 当前帧索引
var walk_timer := 0.0           # 帧计时器
var was_moving := false         # 上一帧是否在移动
const FRAME_W := 48             # 每帧宽度
const FRAME_H := 48             # 每帧高度
const FRAME_GAP := 2            # 帧间距
const ANIM_SPEED := 0.1         # 走步每帧间隔（秒）

# 攻击动画
var is_attacking := false
var attack_frame := 0
var attack_timer := 0.0
const ATTACK_FRAME_COUNT := 16  # 攻击动画总帧数
const ATTACK_SPEED := 0.06      # 攻击每帧间隔（秒）
const ATTACK_TEXTURE := preload("res://Art/Placeholder/hero_attack.png")
const WALK_TEXTURE := preload("res://Art/Placeholder/hero_walk.png")
const IDLE_TEXTURE := preload("res://Art/Placeholder/hero_idle_0.png")
const DEATH_TEXTURE := preload("res://Art/Placeholder/hero_death.png")

# 死亡动画
var is_dying := false
var death_frame := 0
var death_timer := 0.0
const DEATH_FRAME_COUNT := 16
const DEATH_SPEED := 0.08

# ============================================
# 生命周期函数
# ============================================

func _ready():
	Global.level_changed.connect(_on_level_changed)
	Global.hero_died.connect(_on_died)
	Global.skill_level_changed.connect(_on_skill_level_changed)
	Global.hero_took_damage.connect(_on_hero_took_damage)
	Global.load_game_started.connect(_on_load_game_started)
	RelicManager.active_relics_changed.connect(_on_active_relics_changed)

	Global.apply_strength()

	_setup_shield_visual()
	Global.apply_intelligence()

	call_deferred("_check_first_relic")

	Global.health = Global.max_health
	Global.mana = Global.max_mana

	StoneEnchanted.cast(self, mouse_pos, skill_cooldowns)
	Fortuna.cast(self, mouse_pos, skill_cooldowns)

func _process(delta):
	mouse_pos = get_global_mouse_position()

	sprite.rotation = global_position.angle_to_point(mouse_pos)

	_update_walk_animation(delta)

	# 处理受击恢复计时器
	if hit_recovery_timer > 0:
		hit_recovery_timer -= delta
		if hit_recovery_timer <= 0:
			hit_recovery_timer = 0
			Global.is_in_hit_recovery = false

	for skill in skill_cooldowns.keys():
		if skill_cooldowns[skill] > 0:
			skill_cooldowns[skill] -= delta * RelicManager.get_cooldown_multiplier()
			if skill_cooldowns[skill] < 0:
				skill_cooldowns[skill] = 0

	# 如果处于受击恢复状态，不能施法
	# 如果鼠标在底部 HUD 区域，不施法（防止点击技能图标时误触发）
	var mouse_y = get_viewport().get_mouse_position().y
	var hud_top = get_viewport().get_visible_rect().size.y - 100
	if not Global.is_in_hit_recovery and mouse_y < hud_top:
		if Input.is_action_pressed("spell_magic_missile"):
			_cast_skill_by_id(_get_quick_slot_skill("lmb"))
		if Input.is_action_pressed("spell_fireball"):
			_cast_skill_by_id(_get_quick_slot_skill("rmb"))
		if Input.is_action_pressed("spell_shift") or Input.is_key_pressed(KEY_SHIFT):
			_cast_skill_by_id(_get_quick_slot_skill("shift"))
		if Input.is_action_pressed("spell_space"):
			_cast_skill_by_id(_get_quick_slot_skill("space"))
		if Input.is_action_pressed("spell_freezing_spear"):
			_cast_skill_by_id("freezing_spear")
		if Input.is_action_pressed("spell_prayer"):
			_cast_skill_by_id("prayer")
		if Input.is_action_pressed("spell_heal"):
			_cast_skill_by_id("heal")
		if Input.is_action_pressed("spell_mistfog"):
			_cast_skill_by_id("mistfog")
		if Input.is_action_pressed("spell_wrath_of_god"):
			_cast_skill_by_id("wrath_of_god")
		if Input.is_action_pressed("spell_telekinesis"):
			_cast_skill_by_id("telekinesis")
		if Input.is_action_pressed("spell_sacrifice"):
			_cast_skill_by_id("sacrifice")
		if Input.is_action_pressed("spell_holy_light"):
			_cast_skill_by_id("holy_light")
		if Input.is_action_just_pressed("spell_teleport"):
			_cast_skill_by_id("teleport")
		if Input.is_action_just_pressed("spell_fire_walk"):
			_cast_skill_by_id("fire_walk")
		if Input.is_action_pressed("spell_meteor"):
			_cast_skill_by_id("meteor")
		if Input.is_action_pressed("spell_armageddon"):
			_cast_skill_by_id("armageddon")
		if Input.is_action_pressed("spell_poison_cloud"):
			_cast_skill_by_id("poison_cloud")
		if Input.is_action_pressed("spell_dark_ritual"):
			_cast_skill_by_id("dark_ritual")
		if Input.is_action_pressed("spell_nova"):
			_cast_skill_by_id("nova")
		if Input.is_action_pressed("spell_ball_lightning"):
			_cast_skill_by_id("ball_lightning")
		if Input.is_action_pressed("spell_chain_lightning"):
			_cast_skill_by_id("chain_lightning")
	
	# 自动释放（Auto-Cast）系统
	# 遍历所有标记为自动释放的技能，在冷却就绪且有怪物时自动施法
	if not Global.is_in_hit_recovery and not is_dying:
		_process_auto_cast(delta)
	
	# 存档快捷键 (F5)
	if Input.is_action_just_pressed("save_game"):
		_save_game()
	
	# 读档快捷键 (F10)
	if Input.is_action_just_pressed("load_game"):
		_load_game()

func _save_game():
	Global.hero_save_position = global_position
	var success = SaveManager.save_game(1)
	if success:
		_show_save_notification("游戏已保存", Color.GREEN)
	else:
		_show_save_notification("保存失败!", Color.RED)

func _load_game():
	var success = SaveManager.load_game(1)
	if success:
		_show_save_notification("游戏已读取", Color.CYAN)
		_restore_hero_state()
	else:
		_show_save_notification("没有存档或加载失败!", Color.RED)

func _restore_hero_state():
	global_position = Global.hero_save_position
	for skill in skill_cooldowns.keys():
		skill_cooldowns[skill] = 0.0

func _on_load_game_started():
	for skill in skill_cooldowns.keys():
		skill_cooldowns[skill] = 0.0

func _show_save_notification(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	get_parent().add_child(label)
	label.global_position = global_position - Vector2(100, 100)
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 60, 1.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(label.queue_free)

func get_move_speed() -> float:
	# 计算实际移动速度
	# 原版公式：DEXTERITY_ON_SPEED = 0.5, START_VALUE = 65
	# 原版公式：STAMINA_ON_SPEED = 0.35, START_VALUE = 0
	# 受基础速度、敏捷、耐力和全局速度倍率影响
	var base_speed = BASE_MOVE_SPEED + Global.hero_dexterity * 0.5 + Global.hero_stamina * 0.35
	
	# 应用全局速度倍率（包括buff/debuff）
	base_speed *= Global.speed_multiplier
	
	return base_speed

func _update_walk_animation(delta):
	if is_dying:
		death_timer += delta
		if death_timer >= DEATH_SPEED:
			death_timer = 0.0
			death_frame += 1
			if death_frame >= DEATH_FRAME_COUNT:
				is_dying = false
				_die_finished()
				return
		var x = death_frame * (FRAME_W + FRAME_GAP)
		sprite.region_rect = Rect2(x, 0, FRAME_W, FRAME_H)
		return

	if is_attacking:
		attack_timer += delta
		if attack_timer >= ATTACK_SPEED:
			attack_timer = 0.0
			attack_frame += 1
			if attack_frame >= ATTACK_FRAME_COUNT:
				is_attacking = false
				attack_frame = 0
				sprite.texture = WALK_TEXTURE
		if is_attacking:
			var x = attack_frame * (FRAME_W + FRAME_GAP)
			sprite.region_rect = Rect2(x, 0, FRAME_W, FRAME_H)
		return

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_moving = input_dir.length() > 0
	if is_moving:
		if sprite.texture != WALK_TEXTURE:
			sprite.texture = WALK_TEXTURE
		walk_timer += delta
		if walk_timer >= ANIM_SPEED:
			walk_timer = 0.0
			walk_frame = (walk_frame + 1) % 16
		var x = walk_frame * (FRAME_W + FRAME_GAP)
		sprite.region_rect = Rect2(x, 0, FRAME_W, FRAME_H)
	else:
		sprite.texture = IDLE_TEXTURE
		sprite.region_rect = Rect2(0, 0, FRAME_W, FRAME_H)
		walk_frame = 0
		walk_timer = 0.0
	was_moving = is_moving

func start_attack():
	if is_attacking:
		return
	is_attacking = true
	attack_frame = 0
	attack_timer = 0.0
	sprite.texture = ATTACK_TEXTURE

func _physics_process(delta):
	# 获取输入方向（WASD）
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 归一化输入向量，确保斜向移动速度与直线一致
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	
	var is_moving = input_dir.length() > 0
	
	if is_moving:
		# 有输入时：加速到目标速度
		var target_velocity = input_dir * get_move_speed()
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# 无输入时：减速停止（摩擦力）
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()



func _cast_skill_by_id(skill_id: String):
	_cast_skill(skill_id)


func _cast_skill(skill_id: String) -> bool:
	var script = SKILL_SCRIPTS.get(skill_id)
	if not script:
		return false

	if not SKILLS_NO_ATTACK.has(skill_id):
		start_attack()

	if not script.cast(self, mouse_pos, skill_cooldowns):
		return false

	_update_shield_visual()

	if not SKILLS_NO_MULTICAST.has(skill_id):
		_try_multicast(skill_id)

	return true

func _get_quick_slot_skill(slot: String) -> String:
	match slot:
		"lmb":
			var s = Global.quick_slot_lmb
			return s if not s.is_empty() else "magic_missile"
		"rmb":
			var s = Global.quick_slot_rmb
			return s if not s.is_empty() else "fireball"
		"shift":
			return Global.quick_slot_shift
		_:
			return Global.quick_slot_space


# ============================================
# 自动释放（Auto-Cast）系统
# ============================================

var _auto_cast_timer := 0.0
var _auto_cast_interval := 0.1

func _process_auto_cast(_delta: float):
	_auto_cast_timer += _delta
	if _auto_cast_timer < _auto_cast_interval:
		return
	_auto_cast_timer = 0.0

	for skill_id in Global.auto_cast_skills.keys():
		if not Global.auto_cast_skills.get(skill_id, false):
			continue

		if skill_cooldowns.get(skill_id, 0.0) > 0:
			continue

		if not _auto_cast_check_mana(skill_id):
			continue

		_cast_skill_by_id(skill_id)

func _auto_cast_check_mana(skill_id: String) -> bool:
	if Global.free_spells:
		return true
	var level = Global.skill_levels.get(skill_id, 0)
	if level <= 0:
		return false
	var script = SKILL_SCRIPTS.get(skill_id)
	if not script or not script.has_method("get_mana_cost"):
		return true
	return Global.mana >= script.get_mana_cost(level)


func _on_level_changed(lvl):
	var level_label = get_node_or_null("LevelLabel")
	if level_label:
		level_label.text = "Lv." + str(lvl)
	show_level_up_effect()

func _on_skill_level_changed(skill_id: String, _level: int):
	if skill_id == "fortuna":
		Fortuna.update_drop_rate()

func _on_hero_took_damage(_amount: float, _is_magic: bool, attacker: Node):
	# 当英雄受到怪物伤害时，触发受击恢复和减速 debuff
	# 原版：被怪物攻击后减速20%，持续0.5秒
	if attacker != null and attacker.is_in_group("monsters"):
		Global.apply_buff("hit_slow", 0.5, {"multiplier": 0.8})
		
		# 受击恢复系统：被攻击后一段时间内不能施法
		# 原版公式：hit_recovery = max(0.1, 0.5 - strength * 0.004)
		# 每次受击刷新恢复时间
		Global.is_in_hit_recovery = true
		hit_recovery_timer = Global.hit_recovery_time
		
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("shake"):
			cam.shake(3.0)

func show_level_up_effect():
	var glow = Sprite2D.new()
	glow.texture = _create_circle_texture(24, Color(1.0, 0.9, 0.3))
	glow.modulate = Color(1.0, 0.9, 0.3, 0.5)
	glow.scale = Vector2(1.0, 1.0)
	add_child(glow)
	
	var tween = create_tween()
	tween.tween_property(glow, "modulate:a", 0.0, 2.0)
	tween.parallel().tween_property(glow, "scale", Vector2(1.8, 1.8), 2.0)
	tween.tween_callback(glow.queue_free)
	
	var label = Label.new()
	label.text = "LEVEL UP!"
	label.modulate = Color(1.0, 0.9, 0.0, 1.0)
	label.position = Vector2(-40, -80)
	add_child(label)
	
	var label_tween = create_tween()
	label_tween.tween_property(label, "position:y", -120, 2.0)
	label_tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	label_tween.tween_callback(label.queue_free)

static func _create_circle_texture(radius: int, color: Color = Color.WHITE) -> ImageTexture:
	var diameter = radius * 2
	var image = Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center = Vector2(radius, radius)
	var radius_sq = radius * radius
	for y in range(diameter):
		for x in range(diameter):
			if Vector2(x, y).distance_squared_to(center) <= radius_sq:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

var shield_sprite: Sprite2D = null

func _setup_shield_visual():
	if shield_sprite:
		shield_sprite.queue_free()
		shield_sprite = null
	if not RelicManager.has_relic("shield"):
		return
	shield_sprite = Sprite2D.new()
	shield_sprite.name = "ShieldBubble"
	shield_sprite.texture = _create_shield_circle_texture(32)
	shield_sprite.modulate = Color(0.3, 0.6, 1.0, 0.4)
	shield_sprite.scale = Vector2(2.0, 2.0)
	shield_sprite.z_index = 10
	add_child(shield_sprite)

func _on_active_relics_changed(_relic_ids: Array):
	_setup_shield_visual()

func _update_shield_visual():
	if not shield_sprite:
		return
	if is_instance_valid(shield_sprite):
		shield_sprite.visible = RelicManager.get_shield_active()

func _create_shield_circle_texture(radius: int) -> ImageTexture:
	var diameter = radius * 2
	var image = Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center = Vector2(radius, radius)
	for y in range(diameter):
		for x in range(diameter):
			var dist = Vector2(x, y).distance_squared_to(center)
			var max_dist = radius * radius
			var inner = (radius - 3) * (radius - 3)
			if dist >= inner and dist <= max_dist:
				var alpha = 1.0
				if dist > (radius - 1) * (radius - 1):
					alpha = 1.0 - (sqrt(dist) - (radius - 1)) * 0.5
				image.set_pixel(x, y, Color(1, 1, 1, alpha * 0.8))
	return ImageTexture.create_from_image(image)

func shield_break_effect():
	if not shield_sprite or not is_instance_valid(shield_sprite):
		return
	var original_modulate = shield_sprite.modulate
	shield_sprite.modulate = Color(1, 1, 1, 0.8)
	var tween = create_tween()
	tween.tween_property(shield_sprite, "modulate", original_modulate, 0.3)

func _try_multicast(skill_id: String):
	if not RelicManager.has_relic("multicast"):
		return
	get_tree().create_timer(0.2).timeout.connect(func():
		if not is_instance_valid(self):
			return
		if randf() < 0.15:
			_show_multicast_text()
			var saved_cd = skill_cooldowns.get(skill_id, 0.0)
			var saved_free = Global.free_spells
			skill_cooldowns[skill_id] = 0.0
			Global.free_spells = true
			_cast_skill_by_id(skill_id)
			skill_cooldowns[skill_id] = saved_cd
			Global.free_spells = saved_free
	)

func _show_multicast_text():
	var label = Label.new()
	label.text = "Multicast!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 0.4, 0.8, 1))
	label.add_theme_color_override("font_outline_color", Color(0.3, 0, 0.2, 1))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-60, -80)
	label.size = Vector2(120, 30)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func _check_first_relic():
	if RelicManager.active_relic_ids.is_empty() and RelicManager.is_relic_level(1):
		Global.start_first_relic_selection()

# 所有 cast 函数已统一为 _cast_skill(skill_id) 通过 _cast_skill_by_id 分发
# 特殊行为（无攻击动画 / 无多重施法）通过 SKILLS_NO_ATTACK / SKILLS_NO_MULTICAST 控制

func _on_died():
	if is_dying:
		return
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)
	
	is_dying = true
	death_frame = 0
	death_timer = 0.0
	sprite.texture = DEATH_TEXTURE
	set_process(true)

func _die_finished():
	visible = false
	set_process(false)
	
	if Global.current_game_mode == Global.GameMode.SURVIVAL:
		var game_over_scene = preload("res://Scenes/GameOverScreen.tscn")
		var game_over = game_over_scene.instantiate()
		get_tree().current_scene.add_child(game_over)
		var stats = {
			"monsters_killed": 0,
			"hero_level": Global.hero_level,
			"experience_gained": Global.survival_total_exp_gained
		}
		game_over.show_game_over("survival", stats)

func respawn():
	Global.reset()
	hit_recovery_timer = 0.0
	Global.is_in_hit_recovery = false
	visible = true
	set_process(true)
	set_physics_process(true)
	set_process_unhandled_input(true)
