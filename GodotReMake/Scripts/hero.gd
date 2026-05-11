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
# - HealthBar: 头顶血条
# - ManaBar: 头顶蓝条
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

# 基础移动速度（像素/秒）
# 原版公式：DEXTERITY_ON_SPEED = 0.5, START_VALUE = 65
# 原版公式：STAMINA_ON_SPEED = 0.35, START_VALUE = 0
# 实际速度 = 65 + 敏捷×0.5 + 耐力×0.35
const BASE_MOVE_SPEED := 65.0

# 加速度和摩擦力（用于平滑移动）
# 值越大，角色启动和停止越快
@export var acceleration := 1200.0
@export var friction := 800.0

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

# ============================================
# 生命周期函数
# ============================================

func _ready():
	Global.health_changed.connect(_on_health_changed)
	Global.mana_changed.connect(_on_mana_changed)
	Global.level_changed.connect(_on_level_changed)
	Global.hero_died.connect(_on_died)
	Global.skill_level_changed.connect(_on_skill_level_changed)
	Global.hero_took_damage.connect(_on_hero_took_damage)

	Global.apply_strength()
	Global.apply_intelligence()

	Global.health = Global.max_health
	Global.mana = Global.max_mana

	StoneEnchanted.cast(self, mouse_pos, skill_cooldowns)
	Fortuna.cast(self, mouse_pos, skill_cooldowns)

func _process(delta):
	mouse_pos = get_global_mouse_position()

	sprite.rotation = global_position.angle_to_point(mouse_pos)

	update_hud()

	for skill in skill_cooldowns.keys():
		if skill_cooldowns[skill] > 0:
			skill_cooldowns[skill] -= delta
			if skill_cooldowns[skill] < 0:
				skill_cooldowns[skill] = 0

	if Input.is_action_pressed("spell_magic_missile"):
		cast_magic_missile()
	if Input.is_action_pressed("spell_fireball"):
		cast_fireball()
	if Input.is_action_pressed("spell_freezing_spear"):
		cast_freezing_spear()
	if Input.is_action_pressed("spell_prayer"):
		cast_prayer()
	if Input.is_action_pressed("spell_heal"):
		cast_heal()
	if Input.is_action_pressed("spell_teleport"):
		cast_teleport()
	if Input.is_action_pressed("spell_mistfog"):
		cast_mistfog()
	if Input.is_action_pressed("spell_wrath_of_god"):
		cast_wrath_of_god()
	if Input.is_action_pressed("spell_telekinesis"):
		cast_telekinesis()
	if Input.is_action_pressed("spell_sacrifice"):
		cast_sacrifice()
	if Input.is_action_pressed("spell_holy_light"):
		cast_holy_light()
	if Input.is_action_pressed("spell_fire_walk"):
		cast_fire_walk()
	if Input.is_action_pressed("spell_meteor"):
		cast_meteor()
	if Input.is_action_pressed("spell_armageddon"):
		cast_armageddon()
	if Input.is_action_pressed("spell_poison_cloud"):
		cast_poison_cloud()
	if Input.is_action_pressed("spell_dark_ritual"):
		cast_dark_ritual()
	if Input.is_action_pressed("spell_nova"):
		cast_nova()
	if Input.is_action_pressed("spell_ball_lightning"):
		cast_ball_lightning()
	if Input.is_action_pressed("spell_chain_lightning"):
		cast_chain_lightning()
	
	# 存档快捷键 (F5)
	if Input.is_action_just_pressed("save_game"):
		_save_game()
	
	# 读档快捷键 (F10)
	if Input.is_action_just_pressed("load_game"):
		_load_game()

func _save_game():
	var success = SaveManager.save_game(1)
	if success:
		print("游戏已保存! 按F9读取")
	else:
		print("保存失败!")

func _load_game():
	var success = SaveManager.load_game(1)
	if success:
		print("游戏已加载!")
	else:
		print("没有存档或加载失败!")

func get_move_speed() -> float:
	# 计算实际移动速度
	# 原版公式：DEXTERITY_ON_SPEED = 0.5, START_VALUE = 65
	# 原版公式：STAMINA_ON_SPEED = 0.35, START_VALUE = 0
	# 受基础速度、敏捷、耐力和全局速度倍率影响
	var base_speed = BASE_MOVE_SPEED + Global.hero_dexterity * 0.5 + Global.hero_stamina * 0.35
	
	# 应用全局速度倍率（包括buff/debuff）
	base_speed *= Global.speed_multiplier
	
	return base_speed

func _physics_process(delta):
	# 物理帧执行：处理移动和碰撞
	
	# 获取输入方向（WASD）
	# 返回Vector2，例如按W返回(0, -1)
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 计算目标速度 = 方向 × 移动速度 × 全局速度倍率（药水等）
	var target_velocity = input_dir * get_move_speed() * Global.speed_multiplier
	
	# 平滑过渡到目标速度（加速度效果）
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	
	# 执行移动并处理碰撞
	move_and_slide()
	
	# 检测与怪物的碰撞
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		if col.get_collider().is_in_group("monsters"):
			pass  # 碰撞处理（预留）

func _unhandled_input(event):
	if event.is_action_pressed("spell_magic_missile"):
		cast_magic_missile()
	if event.is_action_pressed("spell_fireball"):
		cast_fireball()
	if event.is_action_pressed("spell_freezing_spear"):
		cast_freezing_spear()
	if event.is_action_pressed("spell_prayer"):
		cast_prayer()
	if event.is_action_pressed("spell_heal"):
		cast_heal()
	if event.is_action_pressed("spell_teleport"):
		cast_teleport()
	if event.is_action_pressed("spell_mistfog"):
		cast_mistfog()
	if event.is_action_pressed("spell_wrath_of_god"):
		cast_wrath_of_god()
	if event.is_action_pressed("spell_telekinesis"):
		cast_telekinesis()
	if event.is_action_pressed("spell_sacrifice"):
		cast_sacrifice()
	if event.is_action_pressed("spell_holy_light"):
		cast_holy_light()
	if event.is_action_pressed("spell_fire_walk"):
		cast_fire_walk()
	if event.is_action_pressed("spell_meteor"):
		cast_meteor()
	if event.is_action_pressed("spell_armageddon"):
		cast_armageddon()
	if event.is_action_pressed("spell_poison_cloud"):
		cast_poison_cloud()
	if event.is_action_pressed("spell_dark_ritual"):
		cast_dark_ritual()
	if event.is_action_pressed("spell_nova"):
		cast_nova()
	if event.is_action_pressed("spell_ball_lightning"):
		cast_ball_lightning()
	if event.is_action_pressed("spell_chain_lightning"):
		cast_chain_lightning()

func cast_magic_missile():
	MagicMissile.cast(self, mouse_pos, skill_cooldowns)

func cast_fireball():
	Fireball.cast(self, mouse_pos, skill_cooldowns)

func cast_freezing_spear():
	FreezingSpear.cast(self, mouse_pos, skill_cooldowns)

func cast_prayer():
	Prayer.cast(self, mouse_pos, skill_cooldowns)

func cast_heal():
	Heal.cast(self, mouse_pos, skill_cooldowns)

func cast_teleport():
	Teleport.cast(self, mouse_pos, skill_cooldowns)

func cast_mistfog():
	MistFog.cast(self, mouse_pos, skill_cooldowns)

func cast_wrath_of_god():
	WrathOfGod.cast(self, mouse_pos, skill_cooldowns)

func cast_telekinesis():
	Telekinesis.cast(self, mouse_pos, skill_cooldowns)

func cast_sacrifice():
	Sacrifice.cast(self, mouse_pos, skill_cooldowns)

func cast_holy_light():
	HolyLight.cast(self, mouse_pos, skill_cooldowns)

func cast_fire_walk():
	FireWalk.cast(self, mouse_pos, skill_cooldowns)

func cast_meteor():
	Meteor.cast(self, mouse_pos, skill_cooldowns)

func cast_armageddon():
	Armageddon.cast(self, mouse_pos, skill_cooldowns)

func cast_poison_cloud():
	PoisonCloud.cast(self, mouse_pos, skill_cooldowns)

func cast_fortuna():
	Fortuna.cast(self, mouse_pos, skill_cooldowns)

func cast_dark_ritual():
	DarkRitual.cast(self, mouse_pos, skill_cooldowns)

func cast_nova():
	Nova.cast(self, mouse_pos, skill_cooldowns)

func cast_ball_lightning():
	BallLightning.cast(self, mouse_pos, skill_cooldowns)

func cast_chain_lightning():
	ChainLightning.cast(self, mouse_pos, skill_cooldowns)


func update_hud():
	$HealthBar.value = Global.health / Global.max_health * 100.0
	$ManaBar.value = Global.mana / Global.max_mana * 100.0
	$LevelLabel.text = "Lv." + str(Global.hero_level)

func _on_health_changed(h, _mh):
	$HealthBar.value = h / Global.max_health * 100.0

func _on_mana_changed(m, _mm):
	$ManaBar.value = m / Global.max_mana * 100.0

func _on_level_changed(lvl):
	$LevelLabel.text = "Lv." + str(lvl)
	show_level_up_effect()

func _on_skill_level_changed(skill_id: String, _level: int):
	if skill_id == "fortuna":
		Fortuna.update_drop_rate()

func _on_hero_took_damage(_amount: float, _is_magic: bool, attacker: Node):
	# 当英雄受到怪物伤害时，触发减速 debuff
	# 原版：被怪物攻击后减速20%，持续0.5秒
	if attacker != null and attacker.is_in_group("monsters"):
		Global.apply_buff("hit_slow", 0.5, {"multiplier": 0.8})

func show_level_up_effect():
	var glow = ColorRect.new()
	glow.color = Color(1.0, 0.9, 0.3, 0.5)
	glow.size = Vector2(128, 128)
	glow.position = Vector2(-64, -64)
	add_child(glow)
	
	var tween = create_tween()
	tween.tween_property(glow, "color:a", 0.0, 2.0)
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

func _on_died():
	visible = false
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)

func respawn():
	Global.reset()
	visible = true
	set_process(true)
	set_physics_process(true)
	set_process_unhandled_input(true)
	update_hud()
