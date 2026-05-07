# Evil Invasion Remake — 新 Agent 交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-07
> **项目位置**: `e:\EvilInvasion\GodotReMake\`

---

## 📋 必读文档（按顺序）

1. **`DEVELOPER_HANDOVER.md`** — 详细的开发者交接文档（文件结构、核心系统、技术债务、下一步建议）
2. **`ROADMAP.md`** — 完整开发路线图和原版游戏参数参考
3. **`SPELL_DEVELOPMENT_GUIDE.md`** — 技能开发规范（必须遵守）
4. **`extracted.md`** — 原版游戏反编译数据（技能数值、怪物参数等）

---

## 🎯 当前核心任务

### 上一个 Agent 已完成的工作（2026-05-07）

1. **重构了 3 个技能为独立场景**：
   - ✅ **Magic Missile** (`MagicMissile.tscn` + `magic_missile.gd`)
     - 特性：追踪目标、发射后缓慢加速、转弯减速效果、10秒生命周期
     - 伤害属性：basic
   - ✅ **Fireball** (`Fireball.tscn` + `fireball.gd`)
     - 特性：直线飞行、命中后爆炸AOE、fire属性伤害
   - ✅ **Freezing Spear** (`FreezingSpear.tscn` + `freezing_spear.gd`)
     - 特性：直线穿透、冰冻敌人1秒（不能移动不能攻击）、water属性伤害
     - 按键：Z

2. **更新了伤害类型系统**：
   - 五种元素属性：basic, earth, air, fire, water
   - 所有技能按系别分配对应属性

3. **实现了技能独立冷却系统**：
   - 每个技能有自己的冷却时间，互不干扰
   - 可同时施放多个技能（如左键+右键+Z同时按）
   - 长按可持续施法（受冷却限制）

4. **移除了 Lightning 技能**（LLM幻觉技能）

5. **实现了技能数据封装**：
   - 各技能脚本管理自己的冷却、伤害、法力消耗
   - hero.gd 不再包含技能数据，只负责调用

### 你的首要任务

**继续重构剩余的 18 个技能为独立场景**

这是用户明确要求的架构改进。上一个 Agent 已经建立了清晰的模式，你只需要复制这个模式。

**必须遵守 `SPELL_DEVELOPMENT_GUIDE.md` 中的规范。**

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

### hero.gd 中的调用方式

```gdscript
const MagicMissile = preload("res://Scripts/magic_missile.gd")

func cast_magic_missile():
    MagicMissile.cast(self, mouse_pos, skill_cooldowns)
```

---

## 📊 待重构技能清单（18个）

按系别分组，建议按此顺序重构：

### Earth 系（5个）
| 技能 | 伤害属性 | 实现方式 | 难度 |
|------|----------|----------|------|
| Prayer | - | Buff/治疗自身 | ⭐⭐ |
| Teleport | - | 位移到鼠标位置 | ⭐⭐ |
| MistFog | - | 区域减速（Area2D） | ⭐⭐⭐ |
| StoneEnchanted | - | 被动技能 | ⭐ |
| WrathOfGod | earth | 全屏AOE | ⭐⭐⭐ |

### Air 系（3个）
| 技能 | 伤害属性 | 实现方式 | 难度 |
|------|----------|----------|------|
| Telekinesis | - | 拾取远处物品 | ⭐⭐ |
| HolyLight | air | 射线检测 | ⭐⭐⭐ |
| Sacrifice | air | 消耗生命秒杀 | ⭐⭐ |

> **注意**：BallLightning 和 ChainLightning 是 LLM 幻觉技能，已移除。Air 系目前只有 3 个技能。

### Fire 系（4个）
| 技能 | 伤害属性 | 实现方式 | 难度 |
|------|----------|----------|------|
| Heal | - | 持续回血 | ⭐⭐ |
| FireWalk | fire | 被动/留下火焰 | ⭐⭐⭐ |
| Meteor | fire | 延迟AOE | ⭐⭐⭐ |
| Armageddon | fire | 全屏随机伤害 | ⭐⭐⭐ |

### Water 系（4个）
| 技能 | 伤害属性 | 实现方式 | 难度 |
|------|----------|----------|------|
| PoisonCloud | water | 区域持续伤害 | ⭐⭐⭐ |
| Fortuna | - | 被动/增加掉率 | ⭐ |
| DarkRitual | water | 延迟秒杀 | ⭐⭐⭐ |
| Nova | water | 自身圆形AOE | ⭐⭐⭐ |

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

> **注意**：ball_lightning 和 chain_lightning 是 LLM 幻觉技能，已移除。

### 3. 当前按键绑定
- 鼠标左键：Magic Missile
- 鼠标右键：Fireball
- Z：Freezing Spear
- 其余技能未绑定按键

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
2. **先重构简单的技能**（如 Prayer、Fortuna、StoneEnchanted），再处理复杂的
3. **保持代码风格一致**：
   - snake_case 命名变量和函数
   - PascalCase 命名类名和节点名
   - UPPER_SNAKE_CASE 命名常量
   - Tab 缩进
4. **测试时关注 Output 面板**，Godot 的报错信息很详细
5. **每次重构一个技能后运行测试**，确保没有破坏现有功能

---

## 📁 关键文件速查

| 文件 | 用途 |
|------|------|
| `Scripts/global.gd` | 全局状态（Autoload） |
| `Scripts/hero.gd` | 英雄控制 + 技能调用（~990行） |
| `Scripts/monster.gd` | 怪物 AI |
| `Scripts/magic_missile.gd` | ✅ 参考模板（追踪投射物） |
| `Scripts/fireball.gd` | ✅ 参考模板（爆炸AOE） |
| `Scripts/freezing_spear.gd` | ✅ 参考模板（穿透+冰冻） |
| `Scenes/MagicMissile.tscn` | ✅ 参考场景 |
| `Scenes/Fireball.tscn` | ✅ 参考场景 |
| `Scenes/FreezingSpear.tscn` | ✅ 参考场景 |
| `SPELL_DEVELOPMENT_GUIDE.md` | 技能开发规范（必须遵守） |
| `project.godot` | 输入映射配置 |

---

## 🚀 开始工作

1. 阅读 `DEVELOPER_HANDOVER.md` 了解项目全貌
2. 阅读 `SPELL_DEVELOPMENT_GUIDE.md` 了解技能开发规范
3. 运行游戏，按 F2 进入 DevMode 测试现有技能
4. 选择一个待重构的技能（建议从 Prayer 或 Heal 开始）
5. 参考 `magic_missile.gd` / `fireball.gd` / `freezing_spear.gd` 的代码结构
6. 创建新的 `.tscn` + `.gd` 文件
7. 在 `hero.gd` 中更新调用逻辑
8. 在 `global.gd` 中添加技能等级
9. 测试并验证

---

**祝开发顺利！**
