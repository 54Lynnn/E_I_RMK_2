# Evil Invasion Remake — 新 Agent 交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-08
> **项目位置**: `e:\EvilInvasion\GodotReMake\`

---

## 📋 必读文档（按顺序）

1. **`DEVELOPER_HANDOVER.md`** — 详细的开发者交接文档（文件结构、核心系统、技术债务、下一步建议）
2. **`ROADMAP.md`** — 完整开发路线图和原版游戏参数参考
3. **`SPELL_DEVELOPMENT_GUIDE.md`** — 技能开发规范（必须遵守）
4. **`extracted.md`** — 原版游戏反编译数据（⚠️ 技能数值部分已删除，存在等级偏移错误。技能数值请以 `E:\EvilInvasion\evil_invasion_spell.xlsx` 为准）

---

## 🎯 当前核心任务

### ✅ 技能重构已完成（2026-05-08）

**全部21个技能已重构为独立场景/脚本！**

1. **投射物类（3个）**：
   - ✅ Magic Missile — 追踪+加速+转弯减速
   - ✅ Fireball — 直线飞行+爆炸AOE
   - ✅ Freezing Spear — 直线穿透+冰冻

2. **持续效果类（2个）**：
   - ✅ Prayer — 扣血回蓝+蓝色粒子
   - ✅ Heal — 持续回血+红色+号粒子

3. **位移/区域类（9个）**：
   - ✅ Teleport — 位移到鼠标位置
   - ✅ MistFog — 区域减速
   - ✅ HolyLight — 射线伤害
   - ✅ FireWalk — 火焰轨迹
   - ✅ Meteor — 延迟AOE
   - ✅ Armageddon — 全屏随机伤害
   - ✅ PoisonCloud — 区域持续伤害
   - ✅ Nova — 自身圆形AOE
   - ✅ DarkRitual — 延迟秒杀

4. **即时效果类（3个）**：
   - ✅ WrathOfGod — 全屏AOE
   - ✅ Telekinesis — 隔空取物
   - ✅ Sacrifice — 消耗生命秒杀

5. **被动技能类（3个）**：
   - ✅ StoneEnchanted — 被击石化反击
   - ✅ Telekinesis — 鼠标悬停自动拾取
   - ✅ Fortuna — 增加掉落率

6. **其他类（2个）**：
   - ✅ BallLightning — 银球自动攻击附近敌人
   - ✅ ChainLightning — 闪电矛弹跳3次

6. **架构改进**：
   - hero.gd 完全重构：所有技能调用改为 `SkillName.cast()` 模式
   - 各技能脚本管理自己的冷却、伤害、法力消耗
   - 全部21个技能已绑定按键（见下方按键表）

### 你的首要任务

**技能重构阶段已完成。下一步建议：**

1. **添加音效** — 所有技能目前没有音效
2. **扩展怪物种类** — 目前只有蜘蛛和僵尸，需添加熊、弓手、恶魔、死神等
3. **实现存档系统** — 使用 FileAccess + JSON
4. **添加地图/关卡系统** — 原版有多张地图
5. **优化技能平衡性** — 测试并调整技能数值
6. **完善UI** — 添加系别头像、更好的技能提示框等

请根据用户具体要求选择下一步工作。

---

## 🔧 技能重构模式（参考模板）

### 已完成技能的结构（以此为模板）

**Magic Missile** (`Scripts/magic_missile.gd`):
```gdscript
extends Area2D

# ============================================
# 技能配置（所有数据必须在此定义）
# ============================================
static var skill_name := "magic_missile"
static var base_cooldown := 1.0
static var base_mana_cost := 5.0
static var base_damage := 5.0
static var damage_element := "basic"

# 等级成长公式
static func get_mana_cost(level: int) -> float:
    return base_mana_cost + level

static func get_damage(level: int) -> float:
    return base_damage + level * 5.0

# 施法入口
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
    var level = Global.skill_levels.get(skill_name, 0)
    if level <= 0:
        return false
    if skill_cooldowns.get(skill_name, 0.0) > 0:
        return false
    
    var mana_cost = get_mana_cost(level)
    var damage = get_damage(level)
    
    if Global.free_spells or Global.mana >= mana_cost:
        if not Global.free_spells:
            Global.mana -= mana_cost
            Global.mana_changed.emit(Global.mana, Global.max_mana)
        
        # 创建技能效果
        var muzzle = hero.get_node("Sprite2D/Muzzle")
        var missile = preload("res://Scenes/MagicMissile.tscn").instantiate()
        missile.global_position = muzzle.global_position
        missile.direction = hero.global_position.direction_to(mouse_pos)
        missile.damage = damage
        hero.get_parent().add_child(missile)
        
        skill_cooldowns[skill_name] = base_cooldown
        return true
    return false

# ============================================
# 实例属性（投射物行为）
# ============================================
@export var speed := 300.0
@export var damage := 10.0
```

**场景结构** (`Scenes/MagicMissile.tscn`):
```
Area2D (根节点)
├── CollisionShape2D (碰撞体)
├── Sprite2D (贴图)
└── CPUParticles2D (粒子特效)
```

### hero.gd 中的调用方式（已重构技能）

```gdscript
const MagicMissile = preload("res://Scripts/magic_missile.gd")

func cast_magic_missile():
    MagicMissile.cast(self, mouse_pos, skill_cooldowns)
```

### hero.gd 中的调用方式（全部技能）

```gdscript
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
```

被动技能（StoneEnchanted、Fortuna）在 `_ready()` 中自动触发：
```gdscript
func _ready():
    StoneEnchanted.cast(self, mouse_pos, skill_cooldowns)
    Fortuna.cast(self, mouse_pos, skill_cooldowns)
```

---

## ⚠️ 重要注意事项

### 1. 技能名称一致性（极其重要）
技能名称必须在所有文件中保持一致：
- 脚本内 `skill_name`：`"magic_missile"`
- `global.gd` 的 `skill_levels` key：`"magic_missile"`
- `hero.gd` 的 `skill_cooldowns` key：`"magic_missile"`
- `project.godot` 的输入动作名：`spell_magic_missile`

### 2. 伤害属性分配（必须遵守）
```
basic:  magic_missile
earth:  stone_enchanted, wrath_of_god
air:    holy_light, sacrifice
fire:   fireball, fire_walk, meteor, armageddon
water:  freezing_spear, poison_cloud, dark_ritual, nova
```

> **注意**：ball_lightning 和 chain_lightning 是原版Air系技能，已实现。

### 3. 当前按键绑定（全部21个技能）
- 鼠标左键：Magic Missile
- 鼠标右键：Fireball
- Z：Freezing Spear
- X：Prayer
- C：Heal
- 2：Teleport
- 3：Mist Fog
- 4：Wrath of God
- Q：Telekinesis
- R：Sacrifice
- E：Holy Light
- U：Fire Walk
- F：Meteor
- G：Armageddon
- H：Poison Cloud
- V：Fortuna（被动，无需按键）
- B：Dark Ritual
- N：Nova
- I：Ball Lightning
- O：Chain Lightning

### 4. 伤害系统
- 技能伤害是**固定值**，不包含英雄属性加成
- 伤害仅与技能等级相关
- 禁止在伤害计算中加入 `Global.hero_intelligence` 等属性

### 5. Muzzle 节点路径
获取发射口时必须使用正确路径：
```gdscript
var muzzle = hero.get_node("Sprite2D/Muzzle")  # ✅ 正确
var muzzle = hero.get_node("Muzzle")             # ❌ 错误，会返回 null
```

### 6. 碰撞层级
- 怪物：`collision_layer = 4`（第3层）
- 投射物：`collision_mask = 4`（检测第3层）

### 7. 怪物冰冻机制
- Freezing Spear 通过修改 `monster.move_speed = 0.0` 和 `monster.can_attack = false` 实现冰冻
- 需要验证是否与其他减速效果冲突

### 8. 用户偏好
- 用户使用中文交流
- 用户会提供原版游戏截图作为参考
- 用户重视视觉还原度
- 用户要求"一个技能一个场景"的架构

### 9. 常见陷阱
- **技能图标路径**：`res://Art/Placeholder/SkillName.png`，注意大小写
- **节点引用**：修改场景后确保脚本中的 `@onready` 引用正确
- **法力/生命修改后**：必须发射信号（如 `Global.mana_changed.emit()`）
- **`await` 滥用**：注意内存泄漏

---

## 💡 开发建议

1. **先运行游戏**，按 F2 进入 DevMode，测试现有功能
2. **保持代码风格一致**：
   - snake_case 命名变量和函数
   - PascalCase 命名类名和节点名
   - UPPER_SNAKE_CASE 命名常量
   - Tab 缩进
3. **测试时关注 Output 面板**，Godot 的报错信息很详细
4. **每次修改后运行测试**，确保没有破坏现有功能

---

## 📁 关键文件速查

| 文件 | 用途 |
|------|------|
| `Scripts/global.gd` | 全局状态（Autoload） |
| `Scripts/hero.gd` | 英雄控制 + 技能调用 |
| `Scripts/monster.gd` | 怪物 AI |
| `Scripts/magic_missile.gd` | ✅ 追踪投射物 |
| `Scripts/fireball.gd` | ✅ 爆炸AOE |
| `Scripts/freezing_spear.gd` | ✅ 穿透+冰冻 |
| `Scripts/prayer.gd` | ✅ 持续效果+粒子 |
| `Scripts/heal.gd` | ✅ 持续效果+粒子 |
| `Scripts/teleport.gd` | ✅ 位移技能 |
| `Scripts/mistfog.gd` | ✅ 区域减速 |
| `Scripts/wrath_of_god.gd` | ✅ 全屏AOE |
| `Scripts/holy_light.gd` | ✅ 射线伤害 |
| `Scripts/fire_walk.gd` | ✅ 火焰轨迹 |
| `Scripts/meteor.gd` | ✅ 延迟AOE |
| `Scripts/armageddon.gd` | ✅ 全屏随机伤害 |
| `Scripts/poison_cloud.gd` | ✅ 区域持续伤害 |
| `Scripts/nova.gd` | ✅ 自身圆形AOE |
| `Scripts/dark_ritual.gd` | ✅ 延迟秒杀 |
| `Scripts/telekinesis.gd` | ✅ 隔空取物 |
| `Scripts/sacrifice.gd` | ✅ 消耗生命秒杀 |
| `Scripts/stone_enchanted.gd` | ✅ 被动石化 |
| `Scripts/fortuna.gd` | ✅ 被动掉率 |
| `SPELL_DEVELOPMENT_GUIDE.md` | 技能开发规范 |
| `project.godot` | 输入映射配置 |

---

## 🚀 开始工作

1. 阅读 `DEVELOPER_HANDOVER.md` 了解项目全貌
2. 阅读 `SPELL_DEVELOPMENT_GUIDE.md` 了解技能开发规范
3. 运行游戏，按 F2 进入 DevMode 测试现有技能
4. 根据用户要求选择下一步工作（音效/怪物/存档/地图等）
5. 参考现有技能代码结构进行开发
6. 测试并验证

---

**祝开发顺利！**
