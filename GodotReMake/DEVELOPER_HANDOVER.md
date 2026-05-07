# Evil Invasion (Godot 4.6 Remake) - 开发者交接文档

> **项目**: Evil Invasion (2006年Flash游戏重制版)
> **引擎**: Godot 4.6.2-stable
> **语言**: GDScript
> **作者**: [Previous Agent]
> **日期**: 2026-05-06
> **最后更新**: 2026-05-08 (Prayer & Heal 重构完成，hero.gd 清理完成)

---

## 目录

1. [项目概述](#1-项目概述)
2. [项目结构](#2-项目结构)
3. [已完成功能](#3-已完成功能)
4. [核心系统详解](#4-核心系统详解)
5. [技能系统完整说明](#5-技能系统完整说明)
6. [已知问题与技术债务](#6-已知问题与技术债务)
7. [开发路线图](#7-开发路线图)
8. [下一个Agent的工作建议](#8-下一个agent的工作建议)
9. [关键代码文件索引](#9-关键代码文件索引)
10. [用户偏好与注意事项](#10-用户偏好与注意事项)

---

## 1. 项目概述

这是2006年Flash游戏 **Evil Invasion** 的Godot 4.6重制版。原版是一个俯视角动作RPG，玩家控制英雄在地图上击杀怪物、升级、学习技能。

### 当前状态
- 核心游戏循环可运行（移动、攻击、击杀、升级、掉落）
- 完整的21个技能系统（UI + 逻辑）
- **技能重构进行中**：5个技能已提取为独立场景（Magic Missile、Fireball、Freezing Spear、Prayer、Heal）
- **hero.gd 已清理**：删除了15个未重构技能的旧版内联实现，替换为占位符函数
- **技能数据已迁移**：各技能脚本管理自己的冷却、伤害、法力消耗
- **独立冷却系统**：每个技能各自冷却，可同时施放多个技能
- **长按持续施法**：按住技能键可持续施放（受冷却限制）
- 伤害类型系统已更新为五种元素属性（basic, earth, air, fire, water）
- 属性分配系统
- 开发模式（DevMode）用于测试
- 怪物生成与AI（数据驱动，支持多种怪物）
- 拾取物品系统

### 游戏操作
| 按键 | 功能 |
|------|------|
| WASD | 移动 |
| 鼠标左键 | Magic Missile（默认左键技能） |
| 鼠标右键 | Fireball |
| Z | Freezing Spear |
| X | Prayer |
| C | Heal |
| T | 打开/关闭英雄面板（技能树 + 属性分配） |
| F2 | 切换开发模式（DevMode） |

---

## 2. 项目结构

```
GodotReMake/
├── project.godot              # 项目配置和输入映射
├── Scenes/
│   ├── Main.tscn              # 主场景（游戏入口）
│   ├── Hero.tscn              # 玩家英雄场景
│   ├── Monster.tscn           # 蜘蛛场景（共享 monster.gd）
│   ├── Zombie.tscn            # 僵尸场景（共享 monster.gd）✅
│   ├── Projectile.tscn        # 旧版通用投射物（逐步弃用）
│   ├── MagicMissile.tscn      # Magic Missile 独立场景 ✅
│   ├── Fireball.tscn          # Fireball 独立场景 ✅
│   ├── FreezingSpear.tscn     # Freezing Spear 独立场景 ✅
│   ├── Explosion.tscn         # 爆炸特效
│   ├── PickupItem.tscn        # 拾取物品
│   ├── HUD.tscn               # 游戏内HUD（血条/蓝条/经验条）
│   ├── HeroPanel.tscn         # 英雄面板（技能树 + 属性分配）
│   └── SkillButton.tscn       # 技能按钮UI组件
├── Scripts/
│   ├── global.gd              # 全局单例（自动加载）
│   ├── hero.gd                # 英雄逻辑（移动、技能施放）
│   ├── monster.gd             # 怪物AI与行为
│   ├── monster_spawner.gd     # 怪物生成器
│   ├── projectile.gd          # 旧版通用投射物逻辑（逐步弃用）
│   ├── magic_missile.gd       # Magic Missile 独立脚本 ✅
│   ├── fireball.gd            # Fireball 独立脚本 ✅
│   ├── freezing_spear.gd      # Freezing Spear 独立脚本 ✅
│   ├── prayer.gd              # Prayer 独立脚本 ✅
│   ├── heal.gd                # Heal 独立脚本 ✅
│   ├── explosion.gd           # 爆炸特效逻辑
│   ├── pickup_item.gd         # 拾取物品逻辑
│   ├── loot_manager.gd        # 掉落管理器（自动加载）
│   ├── hud.gd                 # HUD更新逻辑
│   ├── hero_panel.gd          # 英雄面板主逻辑
│   ├── skill_button.gd        # 技能按钮组件逻辑
│   └── camera.gd              # 摄像机跟随逻辑
└── Art/
    └── Placeholder/           # 占位美术资源（技能图标等）
```

---

## 3. 已完成功能

### 3.1 英雄系统 (hero.gd)
- [x] WASD移动（带加速度和摩擦力）
- [x] 鼠标瞄准（Sprite旋转指向鼠标）
- [x] 21个技能的施放逻辑（全部实现）
- [x] 法力消耗和冷却系统
- [x] 生命值/法力值自然回复
- [x] 死亡与复活（respawn）
- [x] 升级特效（Level Up文字+光效）

### 3.2 属性系统 (global.gd)
- [x] 5个基础属性：Strength, Dexterity, Stamina, Intelligence, Wisdom
- [x] 属性影响：
  - Strength → 最大生命值 (+10 HP/点)
  - Intelligence → 最大法力值 (+6 MP/点)
  - Wisdom → 最大法力值 (+2 MP/点)
  - Stamina → 生命回复速度
  - Dexterity → 移动速度 (+0.5/点) + 闪避率
- [x] 属性点分配UI（每级+5点）
- [x] 派生属性显示（生命回复、法力回复、速度、受击恢复、被击中几率）

### 3.3 技能系统
- [x] 21个技能全部实现施放逻辑
- [x] 技能树UI（8列×4行绝对定位布局）
- [x] 技能前置条件检查
- [x] 技能等级上限10级
- [x] 技能点分配（每级+1点）
- [x] 技能连线（主枝/旁支连线）
- [x] 技能提示框（鼠标悬停显示描述）
- [x] 技能图标占位资源
- [x] **伤害类型系统**：五种元素属性（basic, earth, air, fire, water）
- [x] **Magic Missile 重构**：独立场景 + 追踪 + 加速 + 转弯减速 + 10秒生命周期
- [x] **Fireball 重构**：独立场景 + 爆炸AOE + fire属性伤害
- [x] **Freezing Spear 重构**：独立场景 + 直线穿透 + 冰冻效果 + water属性伤害
- [x] **Prayer 重构**：独立场景 + 持续扣血回蓝 + 蓝色气泡特效 + 绑定X键
- [x] **Heal 重构**：独立场景 + 持续回血 + 红色+号特效 + 绑定C键
- [x] **技能数据迁移**：冷却、伤害、法力消耗已移至各技能脚本
- [x] **hero.gd 清理**：删除15个未重构技能的旧版内联实现，替换为占位符函数
- [ ] **其余13个技能**：仍使用占位符函数，待重构为独立场景

### 3.4 技能树布局（最终版）

**第0行（顶层）：**
| 列0 | 列1 | 列2 | 列3 | 列4 | 列5 | 列6 | 列7 |
|-----|-----|-----|-----|-----|-----|-----|-----|
| StoneEnchanted | WrathOfGod | BallLightning | ChainLightning | Meteor | Armageddon | DarkRitual | Nova |

**第1行：**
| Teleport | MistFog | HolyLight | Sacrifice | Heal | FireWalk | PoisonCloud | Fortuna |

**第2行：**
| Prayer | (空) | Telekinesis | (空) | FireBall | (空) | FreezingSpear | (空) |

**第3行（底层）：**
| (空) | (空) | (空) | **MagicMissile** | (空) | (空) | (空) | (空) |

**主枝/旁支结构：**
- Earth系: Prayer → Teleport(主) / MistFog(旁) → StoneEnchanted(主) / WrathOfGod(旁)
- Air系: Telekinesis → HolyLight(主) / Sacrifice(旁) → BallLightning(主) / ChainLightning(旁)
- Fire系: FireBall → Heal(主) / FireWalk(旁) → Meteor(主) / Armageddon(旁)
- Water系: FreezingSpear → PoisonCloud(主) / Fortuna(旁) → DarkRitual(主) / Nova(旁)

### 3.5 怪物系统 (monster.gd)
- [x] 状态机（IDLE, CHASE, ATTACK, HURT, DEATH）
- [x] 追踪玩家（检测范围400px）
- [x] 近战攻击（攻击范围40px，冷却2秒）
- [x] 受击闪烁（红色闪烁）
- [x] 死亡动画（淡出）
- [x] 经验值掉落
- [x] **数据驱动**：通过场景属性配置怪物参数（血量、速度、伤害、颜色等）
- [x] **多怪物支持**：Spider、Zombie 使用共享 monster.gd 脚本

### 3.6 怪物生成 (monster_spawner.gd)
- [x] 定时生成（间隔2秒）
- [x] 最大数量限制（6只）
- [x] 在玩家周围圆形区域生成（半径400px）

### 3.7 掉落系统 (loot_manager.gd)
- [x] 5种稀有度（Common, Uncommon, Unique, Rare, Exceptional）
- [x] 12种物品类型（药水、卷轴、护盾、增益等）
- [x] 基础掉落率10%（受Fortuna技能影响）
- [x] 物品自动消失（10秒 lifetime）

### 3.8 拾取物品 (pickup_item.gd)
- [x] 12种物品效果全部实现
- [x] 物品贴图加载（BonusXXX.png格式）
- [x] 接触自动拾取
- [x] 消失前1秒渐隐

### 3.9 HUD (hud.gd)
- [x] 生命值条（底部）
- [x] 法力值条
- [x] 经验值条
- [x] 等级显示

### 3.10 摄像机 (camera.gd)
- [x] 平滑跟随玩家
- [x] 缩放0.5（视野翻倍）

### 3.11 开发模式 (DevMode)
- [x] F2切换
- [x] 自动+100属性点、+100技能点
- [x] 游戏暂停
- [x] 可正常打开技能树界面

---

## 4. 核心系统详解

### 4.1 Global单例 (global.gd)

这是整个游戏的核心数据中心，作为自动加载脚本运行。

**关键变量：**
```gdscript
var dev_mode := false                    # 开发模式开关
var hero_level := 1                      # 英雄等级
var hero_experience := 0                 # 当前经验
var attribute_points := 0                # 可用属性点
var skill_points := 0                    # 可用技能点
var skill_levels := {}                   # 各技能等级字典
var health := 100.0 / max_health         # 当前/最大生命
var mana := 50.0 / max_mana              # 当前/最大法力
var damage_multiplier := 1.0             # 伤害倍率（QuadDamage等）
var speed_multiplier := 1.0              # 速度倍率
var free_spells := false                 # 免费施法
var invulnerable := false                # 无敌
var drop_rate_multiplier := 1.0          # 掉落率倍率（Fortuna）
```

**重要方法：**
- `gain_experience(amount)` - 获得经验，自动处理升级
- `take_damage(amount, is_magic)` - 受到伤害（计算抗性）
- `heal(amount)` / `heal_over_time(amount, duration)` - 治疗
- `apply_strength/intelligence/etc()` - 属性变更后更新派生属性
- `activate_xxx(duration)` - 各种临时增益效果

### 4.2 英雄输入处理 (hero.gd)

所有技能通过 `_unhandled_input()` 处理，使用 `InputEventAction` 判断。

**当前输入映射：**
```
spell_magic_missile  → 鼠标左键
spell_fireball       → 鼠标右键
spell_freezing_spear → 键盘 Z
spell_prayer         → 键盘 X
spell_heal           → 键盘 C
...（其余技能未绑定常用按键）
```

**注意：** 已重构的5个技能绑定了输入。其余13个技能使用占位符函数，按键已改为不常用的F12（4194332），防止冲突。

### 4.3 技能施放通用模式

每个技能遵循以下模式：
```gdscript
func cast_xxx():
    var level = Global.skill_levels.get("xxx", 0)
    if level <= 0:
        return  # 未学习该技能
    var mana_cost = xxx - (level - 1) * yyy  # 等级降低消耗
    var cd = max(xxx - (level - 1) * yyy, min_cd)  # 等级降低冷却
    if Global.free_spells or Global.mana >= mana_cost:
        if not Global.free_spells:
            Global.mana -= mana_cost
        can_cast = false
        cast_cooldown.start(cd)
        # 执行技能效果...
```

### 4.4 技能效果实现方式

**新架构（推荐）**：5个技能已重构为独立场景模式：
- 每个技能有独立的 `.tscn` 场景文件 + `.gd` 脚本文件
- 场景包含：Area2D（根节点）+ CollisionShape2D + Sprite2D + CPUParticles2D
- 脚本继承自 Area2D，包含完整的移动、碰撞、伤害、特效逻辑
- hero.gd 中通过 `preload("res://Scenes/XXX.tscn").instantiate()` 创建实例

**已重构技能**：
- Magic Missile (`Scripts/magic_missile.gd` + `Scenes/MagicMissile.tscn`)
- Fireball (`Scripts/fireball.gd` + `Scenes/Fireball.tscn`)
- Freezing Spear (`Scripts/freezing_spear.gd` + `Scenes/FreezingSpear.tscn`)
- Prayer (`Scripts/prayer.gd` + `Scenes/Prayer.tscn`)
- Heal (`Scripts/heal.gd` + `Scenes/Heal.tscn`)

**占位符架构**：其余13个技能使用空函数占位：
- hero.gd 中有 `cast_teleport()`, `cast_mistfog()` 等15个空函数
- 按对应按键会执行 `pass`，不会报错，但没有任何效果
- 需要逐步重构为独立场景，替换空函数为调用 `SkillName.cast()`

**重构建议**：
- 参考 prayer.gd / heal.gd（最新重构的技能，包含持续效果 + 粒子特效）
- 也参考 magic_missile.gd / fireball.gd / freezing_spear.gd（投射物类技能）
- **下一步**：将剩余13个技能逐步重构为独立场景模式

---

## 5. 技能系统完整说明

### 5.1 技能列表（21个）

| # | 技能ID | 名称 | 系别 | 伤害属性 | 前置 | 消耗 | 冷却 | 效果 | 实现状态 |
|---|--------|------|------|----------|------|------|------|------|----------|
| 1 | magic_missile | Magic Missile | 基础 | **basic** | 无 | 5法力 | 0.5s | 发射投射物，伤害10+力量×1.5，追踪+加速+转弯减速 | ✅ 独立场景 |
| 2 | prayer | Prayer | Earth | - | magic_missile | 生命 | 20s | 持续10秒，每秒扣3%生命回5%法力 | ✅ 独立场景 |
| 3 | teleport | Teleport | Earth | - | prayer | 35法力 | 20s | 0.2秒施法后传送到鼠标位置 | ⏳ 占位符 |
| 4 | mistfog | Mist Fog | Earth | - | prayer | 25法力 | 5s | 棕色雾气减速敌人35% | ⏳ 占位符 |
| 5 | stone_enchanted | Stone Enchanted | Earth | - | teleport | 被动 | - | 被击时30%几率石化攻击者 | ⏳ 占位符 |
| 6 | wrath_of_god | Wrath of God | Earth | **earth** | teleport | 55法力 | 2s | 10个锤子环绕飞出，伤害200 | ⏳ 占位符 |
| 7 | telekinesis | Telekinesis | Air | - | magic_missile | 无 | 1.0s | 远距离拾取物品 | ⏳ 占位符 |
| 8 | holy_light | Holy Light | Air | **air** | telekinesis | 35法力 | 1s | 3道光线射向鼠标，伤害120 | ⏳ 占位符 |
| 9 | sacrifice | Sacrifice | Air | **air** | telekinesis | 55%生命 | 3s | 秒杀鼠标附近敌人 | ⏳ 占位符 |
| 10 | ball_lightning | Ball Lightning | Air | **air** | holy_light | 45法力 | 2s | 银球自动攻击附近敌人 | ⏳ 占位符 |
| 11 | chain_lightning | Chain Lightning | Air | **air** | holy_light | 55法力 | 1s | 闪电矛弹跳3次，伤害1000 | ⏳ 占位符 |
| 12 | fireball | Fireball | Fire | **fire** | magic_missile | 10法力 | 0.3s | 发射火球，伤害15+力量×2，爆炸AOE | ✅ 独立场景 |
| 13 | heal | Heal | Fire | - | fireball | 35法力 | 15s | 持续10秒，每秒回复5.5%生命 | ✅ 独立场景 |
| 14 | fire_walk | Fire Walk | Fire | **fire** | fireball | 被动 | - | 留下火焰轨迹，30伤害/秒 | ⏳ 占位符 |
| 15 | meteor | Meteor | Fire | **fire** | heal | 45法力 | 5s | 陨石雨，伤害250，范围130 | ⏳ 占位符 |
| 16 | armageddon | Armageddon | Fire | **fire** | heal | 55法力 | 20s | 全屏随机火blast，伤害250 | ⏳ 占位符 |
| 17 | freezing_spear | Freezing Spear | Water | **water** | magic_missile | 25法力 | 3s | 冰矛直线穿透，伤害50，冻结2秒 | ✅ 独立场景 |
| 18 | poison_cloud | Poison Cloud | Water | **water** | freezing_spear | 35法力 | 5s | 绿色毒雾，60伤害/秒 | ⏳ 占位符 |
| 19 | fortuna | Fortuna | Water | - | freezing_spear | 被动 | - | 增加掉落率15% | ⏳ 占位符 |
| 20 | dark_ritual | Dark Ritual | Water | **water** | poison_cloud | 55法力 | 5.5s | 黑雾，2秒后30%几率秒杀 | ⏳ 占位符 |
| 21 | nova | Nova | Water | **water** | poison_cloud | 45法力 | 2s | 雪球爆炸冻结，伤害200 | ⏳ 占位符 |

**伤害属性分类**：
- **basic**: magic_missile
- **earth**: stone_enchanted, wrath_of_god
- **air**: holy_light, sacrifice, ball_lightning, chain_lightning
- **fire**: fireball, fire_walk, meteor, armageddon
- **water**: freezing_spear, poison_cloud, dark_ritual, nova

### 5.2 技能等级成长

所有技能都有10个等级，每升1级：
- 法力消耗降低（通常每级-1或-2）
- 冷却时间降低（通常每级-0.1s或-0.2s，有最小值）
- 伤害/效果增强（每级固定增量）

**例外：**
- Stone Enchanted / Fire Walk / Fortuna 是被动技能，没有主动消耗和冷却

### 5.3 技能树UI实现 (hero_panel.gd)

**布局系统：**
- 使用绝对定位（Control节点的position属性）
- 8列×4行网格，CELL_SIZE = 56px
- 技能按钮大小40×40px
- 自动居中计算offset

**连线系统：**
- 使用Line2D绘制连接线
- 主枝（同列）：直线连接
- 旁支（跨列）：折线连接（先垂直再水平）

**技能按钮状态：**
- 未学习前置技能：灰色（modulate = Color(0.3, 0.3, 0.3)）+ disabled
- 已学习前置技能：正常颜色 + 可点击
- 满级（10级）：灰色 + disabled

---

## 6. 已知问题与技术债务

### 6.1 高优先级问题

1. **技能重构进行中（13个技能待完成）**
   - ✅ 已重构5个技能：Magic Missile、Fireball、Freezing Spear、Prayer、Heal
   - ⏳ 其余13个技能使用占位符函数（空实现），需要逐步重构
   - **重构模式**：每个技能创建独立的 `.tscn` + `.gd` 文件，参考现有技能的代码结构
   - **重构顺序建议**：按系别分批重构（Earth → Air → Fire → Water）
   - **参考模板**：
     - 投射物类：magic_missile.gd / fireball.gd / freezing_spear.gd
     - 持续效果类：prayer.gd / heal.gd（含粒子特效、Timer管理）

2. **技能视觉效果简陋**
   - ✅ Magic Missile、Fireball、Freezing Spear 已有独立视觉效果（Sprite2D + CPUParticles2D）
   - ⏳ 其余技能使用程序化生成的ColorRect/Line2D
   - 没有音效
   - **建议：** 继续将剩余技能重构为独立场景预制体

3. **怪物种类单一**
   - 目前只有一种怪物（Monster.tscn）
   - 原版有Archer, Bear, Boss, Demon, Reaper, Rig, Spider等多种
   - MonsterType枚举已定义但未使用

4. **Freezing Spear 已知问题**
   - 偶尔出现技能不触发的情况（可能与输入法或按键检测有关）
   - 冰冻效果通过修改 `move_speed` 和 `can_attack` 实现，需要验证是否与其他减速效果冲突

### 6.2 中优先级问题

5. **没有存档系统**
   - 游戏退出后所有进度丢失
   - **建议：** 使用FileAccess实现JSON存档

6. **没有地图/关卡系统**
   - 目前只有一张空地图
   - 原版有多张地图和关卡进度

7. **UI缺少系别头像**
   - 原版技能树顶部有Earth/Air/Fire/Water四个系别的头像
   - 当前布局已预留空间但未添加

8. **技能平衡性未测试**
   - 所有技能的数值是估算的，未经过实际游戏测试
   - 部分技能可能过强或过弱

### 6.3 低优先级问题

9. **代码重复**
   - 很多技能效果创建模式重复（Area2D + CollisionShape2D + ColorRect）
   - 可以提取为通用工具函数

10. **缺少音效和音乐**
    - 没有任何音频

11. **缺少设置菜单**
    - 无法调整音量、分辨率等

12. **HeroPanel.tscn有冗余节点**
    - 场景文件中可能残留旧布局的节点

### 6.4 技术债务

- `global.gd` 中同时存在 `skill_levels` 字典和 `magic_missile_level` 单独变量，应该统一
- `pickup_item.gd` 和 `global.gd` 中都有ItemType枚举，应该统一
- `hero.gd` 中技能函数过长，可以考虑拆分为单独的Skill类或资源
- 很多魔法数字硬编码（如伤害公式、范围等），应该提取为常量或配置

---

## 7. 开发路线图

### Phase 1: 完善核心体验（建议优先）

- [x] **重构 Magic Missile 为独立场景** ✅
  - 创建 MagicMissile.tscn + magic_missile.gd
  - 实现追踪、加速、转弯减速、10秒生命周期
  - 使用 basic 伤害属性

- [x] **重构 Fireball 为独立场景** ✅
  - 创建 Fireball.tscn + fireball.gd
  - 实现爆炸AOE、fire属性伤害

- [x] **重构 Freezing Spear 为独立场景** ✅
  - 创建 FreezingSpear.tscn + freezing_spear.gd
  - 实现直线穿透、冰冻效果、water属性伤害
  - 绑定 Z 键（Armageddon 改为 X 键）

- [x] **更新伤害类型系统** ✅
  - 实现五种元素属性：basic, earth, air, fire, water
  - 所有技能按系别分配对应属性

- [ ] **继续重构剩余18个技能为独立场景**
  - 参考 magic_missile.gd / fireball.gd / freezing_spear.gd 的代码结构
  - 按系别分批重构：Earth → Air → Fire → Water
  - 每个技能创建独立的 `.tscn` + `.gd` 文件

- [ ] **添加系别头像到技能树顶部**
  - 在HeroPanel.tscn的SkillsContainer上方添加4个TextureRect
  - 对应Earth/Air/Fire/Water四系

- [ ] **为所有技能分配键盘快捷键**
  - 目前绑定：左键(Magic Missile)、右键(Fireball)、Z(Freezing Spear)
  - 其余18个技能需要绑定

- [ ] **添加音效系统**
  - 创建AudioManager自动加载脚本
  - 为技能施放、受击、拾取等添加音效占位

### Phase 2: 内容丰富

- [ ] **实现多种怪物**
  - 基于Monster.tscn创建变体场景
  - 实现不同AI（远程Archer、快速Spider、高血Bear等）
  - 使用MonsterType枚举区分

- [ ] **添加Boss战**
  - 创建Boss场景（更大、更强、有特殊技能）
  - 添加Boss血条UI

- [ ] **实现地图系统**
  - 创建TileMap场景
  - 设计多张地图（草地、地牢、雪地等）
  - 添加地图切换逻辑

- [ ] **添加任务/波次系统**
  - 原版是波次防御模式
  - 实现波次生成逻辑和UI显示

### Phase 3: 系统完善

- [ ] **存档系统**
  - 保存：等级、经验、属性、技能等级、物品
  - 使用JSON格式存储到user://

- [ ] **设置菜单**
  - 音量控制
  - 分辨率/全屏
  - 按键绑定（可自定义）

- [ ] **技能视觉效果升级**
  - 为每个技能创建专门的GPUParticles2D或CPUParticles2D
  - 添加屏幕震动、闪光等反馈

- [ ] **平衡性调整**
  - 通过DevMode测试所有技能
  - 调整伤害、消耗、冷却数值

### Phase 4:  polish

- [ ] **开场菜单**
  - 开始游戏、继续、设置、退出

- [ ] **游戏结束画面**
  - 死亡统计、重新开始

- [ ] **成就系统**（可选）

- [ ] **多语言支持**（可选）

---

## 8. 下一个Agent的工作建议

### 如果你是接手的Agent，请按以下顺序工作：

#### 第一步：熟悉项目（30分钟）
1. 运行游戏（F5），测试基本功能
2. 按F2进入DevMode，测试技能树
3. 按T打开英雄面板，测试属性分配
4. 阅读本文档的"已完成功能"和"核心系统详解"

#### 第二步：修复高优先级问题（1-2小时）
1. **添加技能键盘绑定**
   - 询问用户想要的按键方案
   - 修改project.godot和hero.gd
   
2. **添加系别头像**
   - 询问用户是否有头像资源
   - 修改HeroPanel.tscn和hero_panel.gd

3. **创建Magic Missile独立投射物**
   - 复制并修改Projectile.tscn
   - 更新hero.gd中的引用

#### 第三步：根据用户反馈迭代
- 用户通常会有具体的视觉或功能需求
- 先理解需求，再实现
- 保持与现有代码风格一致

#### 第四步：测试与验证
- 每次修改后运行游戏测试
- 使用DevMode测试技能是否正常
- 检查是否有运行时错误

### 代码风格指南
- 使用snake_case命名变量和函数
- 使用PascalCase命名类名和节点名
- 常量使用UPPER_SNAKE_CASE
- 缩进使用Tab（Godot默认）
- 信号使用过去式命名（如skill_upgraded）
- 优先使用类型注解（-> void, -> float等）

### 常见陷阱
1. **project.godot是二进制格式** - 直接文本编辑可能导致格式错误，建议使用Godot编辑器修改输入映射
2. **场景文件(.tscn)格式敏感** - 修改时保持缩进和格式一致
3. **自动加载脚本** - global.gd和loot_manager.gd是自动加载的，修改后无需手动实例化
4. **get_tree().paused** - 暂停会影响所有_process和_physics_process，但_unhandled_input仍然有效

---

## 9. 关键代码文件索引

### 必须理解的文件（按优先级排序）

1. **[global.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/global.gd)** - 游戏全局状态
   - 所有游戏数据的中心
   - 修改前务必理解变量含义
   - **新增**：`damage_multiplier` 用于全局伤害倍率

2. **[hero.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/hero.gd)** - 玩家控制与技能
   - 最长的文件（~990行）
   - 所有技能施放逻辑在这里（21个技能）
   - 输入处理在这里
   - **注意**：Magic Missile、Fireball、Freezing Spear 已提取到独立场景，但 hero.gd 中仍保留调用逻辑

3. **[hero_panel.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/hero_panel.gd)** - 技能树UI
   - 技能树布局和数据定义
   - 技能按钮创建和更新
   - 连线绘制

4. **[skill_button.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/skill_button.gd)** - 技能按钮组件
   - 按钮点击处理（升级技能）
   - 提示框显示

5. **[monster.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/monster.gd)** - 怪物AI
   - 状态机实现
   - 受击和死亡逻辑

6. **[project.godot](file:///e:/EvilInvasion/GodotReMake/project.godot)** - 项目配置
   - 输入映射
   - 自动加载脚本设置
   - 渲染和窗口设置

### 次要文件

7. **[loot_manager.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/loot_manager.gd)** - 掉落系统
8. **[pickup_item.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/pickup_item.gd)** - 拾取物品
9. **[projectile.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/projectile.gd)** - 旧版通用投射物（逐步弃用）
10. **[magic_missile.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/magic_missile.gd)** - Magic Missile 独立脚本 ✅
11. **[fireball.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/fireball.gd)** - Fireball 独立脚本 ✅
12. **[freezing_spear.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/freezing_spear.gd)** - Freezing Spear 独立脚本 ✅
13. **[hud.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/hud.gd)** - HUD更新
14. **[monster_spawner.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/monster_spawner.gd)** - 怪物生成
15. **[camera.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/camera.gd)** - 摄像机
16. **[explosion.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/explosion.gd)** - 爆炸特效

---

## 10. 用户偏好与注意事项

### 用户沟通风格
- 用户使用中文交流
- 用户会提供原版游戏的截图作为参考
- 用户有时会手绘思维导图/草图说明需求
- 用户重视视觉还原度（"参考原版设计"）

### 已实现的设计决策
1. **技能树布局** - 用户明确要求8列×4行的绝对定位布局，主枝/旁支结构
2. **Magic Missile作为默认左键技能** - 用户最新要求
3. **DevMode** - 用户要求用于开发和测试，F2触发
4. **技能图标** - 使用占位资源（Art/Placeholder/XXX.png）

### 待确认的设计决策
1. **技能快捷键方案** - 需要询问用户偏好
2. **系别头像资源** - 需要询问用户是否有资源
3. **游戏模式** - 原版是波次防御还是自由探索？
4. **美术风格** - 是否完全复刻原版像素风？

### 技术限制
- Godot 4.6.2-stable
- Windows平台
- 使用GDScript（非C#）
- 占位美术资源在Art/Placeholder/目录

---

## 附录：快速参考

### 运行项目
```powershell
# 在PowerShell中
cd e:\EvilInvasion\GodotReMake
& "e:\EvilInvasion\Godot_v4.6.2-stable_win64_console.exe" --path .
```

### 检查语法
```powershell
& "e:\EvilInvasion\Godot_v4.6.2-stable_win64_console.exe" --headless --check-only --quit "e:\EvilInvasion\GodotReMake\project.godot"
```

### 项目路径
- 项目根目录：`e:\EvilInvasion\GodotReMake`
- Godot可执行文件：`e:\EvilInvasion\Godot_v4.6.2-stable_win64_console.exe`

---

**文档结束。祝开发顺利！**
