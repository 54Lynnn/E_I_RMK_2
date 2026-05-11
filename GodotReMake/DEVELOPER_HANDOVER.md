# Evil Invasion (Godot 4.6 Remake) - 开发者交接文档

> **项目**: Evil Invasion (2006年Flash游戏重制版)
> **引擎**: Godot 4.6.2-stable
> **语言**: GDScript
> **作者**: [Previous Agent]
> **日期**: 2026-05-06
> **最后更新**: 2026-05-12 (存档系统、受击恢复系统、四种怪物生成模式、文档更新)
> **GitHub仓库**: https://github.com/54Lynnn/E_I_RMK_2

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
- 完整的21个技能系统（UI + 逻辑）- 原版21个技能（含Ball Lightning和Chain Lightning）
- **✅ 技能重构完成**：全部21个技能已提取为独立场景 + 独立脚本
- **hero.gd 已完全重构**：所有技能调用改为 `SkillName.cast(self, mouse_pos, skill_cooldowns)` 模式
- **技能数据已迁移**：各技能脚本管理自己的冷却、伤害、法力消耗
- **独立冷却系统**：每个技能各自冷却，可同时施放多个技能
- **长按持续施法**：按住技能键可持续施放（受冷却限制）
- 伤害类型系统已更新为五种元素属性（basic, earth, air, fire, water）
- 属性分配系统
- 开发模式（DevMode）用于测试
- 怪物生成与AI（数据驱动，支持多种怪物）
- 拾取物品系统
- **✅ 经验值公式简化**：从原版复杂公式简化为 `exp = level * 200`
- **✅ 怪物AI行为更新**：每个怪物有独特的行为模式（详见下方）
- **✅ 统一怪物生成**：所有模式（Quest/Survival）怪物均从地图边缘生成
- **✅ 统一怪物游荡**：所有怪物生成后随机游荡，发现玩家后追击
- **✅ 墙壁反弹游荡**：怪物碰到墙壁像光线反射一样反弹
- **✅ 统一英雄出生点**：Survival和Quest模式英雄均出生在地图中心 (1280, 1280)
- **✅ 存档系统**：F5保存/F10读取，JSON格式，保存英雄状态、属性、技能、位置
- **✅ 受击恢复系统**：被攻击后不能施法+减速20%，力量减少恢复时间
- **✅ 四种怪物生成模式**：单个(1~3秒)/整排(18~22秒)/编组(8~12秒)/全边界(38~42秒)

### 游戏操作
| 按键 | 功能 |
|------|------|
| WASD | 移动 |
| 鼠标左键 | Magic Missile |
| 鼠标右键 | Fireball |
| Z | Freezing Spear |
| X | Prayer |
| C | Heal |
| 2 | Teleport |
| 3 | Mist Fog |
| 4 | Wrath of God |
| Q | Telekinesis |
| R | Sacrifice |
| E | Holy Light |
| U | Fire Walk |
| F | Meteor |
| G | Armageddon |
| H | Poison Cloud |
| V | Fortuna |
| B | Dark Ritual |
| N | Nova |
| I | Ball Lightning |
| O | Chain Lightning |
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
│   ├── Monster.tscn           # 蜘蛛场景
│   ├── Zombie.tscn            # 僵尸场景
│   ├── Bear.tscn              # 熊场景
│   ├── Mummy.tscn             # 木乃伊/弓手场景
│   ├── Reaper.tscn            # 死神场景
│   ├── Demon.tscn             # 恶魔场景
│   ├── Boss.tscn              # Boss场景
│   ├── Projectile.tscn        # 旧版通用投射物（逐步弃用）
│   ├── MagicMissile.tscn      # Magic Missile 独立场景
│   ├── Fireball.tscn          # Fireball 独立场景
│   ├── FreezingSpear.tscn     # Freezing Spear 独立场景
│   ├── Prayer.tscn            # Prayer 独立场景
│   ├── Heal.tscn              # Heal 独立场景
│   ├── Teleport.tscn          # Teleport 独立场景
│   ├── MistFog.tscn           # Mist Fog 独立场景
│   ├── WrathOfGod.tscn        # Wrath of God 独立场景
│   ├── HolyLight.tscn         # Holy Light 独立场景
│   ├── FireWalk.tscn          # Fire Walk 独立场景
│   ├── Meteor.tscn            # Meteor 独立场景
│   ├── Armageddon.tscn        # Armageddon 独立场景
│   ├── PoisonCloud.tscn       # Poison Cloud 独立场景
│   ├── Nova.tscn              # Nova 独立场景
│   ├── DarkRitual.tscn        # Dark Ritual 独立场景
│   ├── BallLightning.tscn     # Ball Lightning 独立场景
│   ├── ChainLightningProj.tscn # Chain Lightning 投射物场景
│   ├── Explosion.tscn         # 爆炸特效
│   ├── PickupItem.tscn        # 拾取物品
│   ├── HUD.tscn               # 游戏内HUD（血条/蓝条/经验条）
│   ├── HeroPanel.tscn         # 英雄面板（技能树 + 属性分配）
│   └── SkillButton.tscn       # 技能按钮UI组件
├── Scripts/
│   ├── global.gd              # 全局单例（自动加载）
│   ├── hero.gd                # 英雄逻辑（移动、技能施放）
│   ├── monster_spawner.gd     # 怪物生成器
│   ├── projectile.gd          # 旧版通用投射物逻辑（逐步弃用）
│   ├── Spells/                # 技能脚本目录
│   │   ├── magic_missile.gd
│   │   ├── fireball.gd
│   │   ├── freezing_spear.gd
│   │   ├── prayer.gd
│   │   ├── heal.gd
│   │   ├── teleport.gd
│   │   ├── mistfog.gd
│   │   ├── wrath_of_god.gd
│   │   ├── telekinesis.gd
│   │   ├── sacrifice.gd
│   │   ├── holy_light.gd
│   │   ├── stone_enchanted.gd
│   │   ├── fire_walk.gd
│   │   ├── meteor.gd
│   │   ├── armageddon.gd
│   │   ├── poison_cloud.gd
│   │   ├── fortuna.gd
│   │   ├── dark_ritual.gd
│   │   ├── nova.gd
│   │   ├── ball_lightning.gd
│   │   └── chain_lightning.gd
│   ├── Monsters/              # 怪物脚本目录
│   │   ├── monster_base.gd
│   │   ├── monster_melee.gd
│   │   ├── monster_ranged.gd
│   │   ├── monster_spider.gd
│   │   ├── monster_zombie.gd
│   │   ├── monster_bear.gd
│   │   ├── monster_mummy.gd (Archer)
│   │   ├── monster_reaper.gd
│   │   ├── monster_demon.gd
│   │   ├── monster_diablo.gd (Boss)
│   │   ├── monster_troll.gd
│   │   └── monster_arrow.gd
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

### 3.3 经验值系统 (global.gd)
- [x] **简化公式**：`exp_to_next = hero_level * 200`
- [x] 每级固定增加200经验值
- [x] 升级时自动回满血和蓝
- [x] 每级获得5属性点 + 1技能点

### 3.4 技能系统
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
- [x] **Teleport 重构**：独立场景 + 位移到鼠标位置 + 2键绑定
- [x] **MistFog 重构**：独立场景 + 区域减速 + 3键绑定
- [x] **WrathOfGod 重构**：独立场景 + 全屏AOE + 4键绑定
- [x] **Telekinesis 重构**：独立场景 + 隔空取物 + Q键绑定
- [x] **Sacrifice 重构**：独立场景 + 消耗生命秒杀 + R键绑定
- [x] **HolyLight 重构**：独立场景 + 射线伤害 + E键绑定
- [x] **StoneEnchanted 重构**：独立脚本 + 被动石化反击
- [x] **FireWalk 重构**：独立场景 + 火焰轨迹 + U键绑定
- [x] **Meteor 重构**：独立场景 + 延迟AOE + F键绑定
- [x] **Armageddon 重构**：独立场景 + 全屏随机伤害 + G键绑定
- [x] **PoisonCloud 重构**：独立场景 + 区域持续伤害 + H键绑定
- [x] **Fortuna 重构**：独立脚本 + 被动增加掉率 + V键绑定
- [x] **DarkRitual 重构**：独立场景 + 延迟秒杀 + B键绑定
- [x] **Nova 重构**：独立场景 + 自身圆形AOE + N键绑定
- [x] **BallLightning 重构**：独立场景 + 银球自动攻击 + I键绑定
- [x] **ChainLightning 重构**：独立场景 + 闪电链弹跳 + O键绑定
- [x] **技能数据迁移**：冷却、伤害、法力消耗已移至各技能脚本
- [x] **hero.gd 完全重构**：所有21个技能调用改为独立脚本模式
- [x] **技能重构全部完成**：21/21个技能已重构为独立场景/脚本

### 3.5 技能树布局（最终版）

**第0行（顶层）：**
| 列0 | 列1 | 列2 | 列3 | 列4 | 列5 | 列6 | 列7 |
|-----|-----|-----|-----|-----|-----|-----|-----|
| StoneEnchanted | WrathOfGod | BallLightning | ChainLightning | Meteor | Armageddon | DarkRitual | Nova |

**第1行：**
| 列0 | 列1 | 列2 | 列3 | 列4 | 列5 | 列6 | 列7 |
|-----|-----|-----|-----|-----|-----|-----|-----|
| Teleport | MistFog | HolyLight | Sacrifice | Heal | FireWalk | PoisonCloud | Fortuna |

**第2行：**
| 列0 | 列1 | 列2 | 列3 | 列4 | 列5 | 列6 | 列7 |
|-----|-----|-----|-----|-----|-----|-----|-----|
| Prayer | (空) | Telekinesis | (空) | FireBall | (空) | FreezingSpear | (空) |

**第3行（底层）：**
| 列0 | 列1 | 列2 | 列3 | 列4 | 列5 | 列6 | 列7 |
|-----|-----|-----|-----|-----|-----|-----|-----|
| (空) | (空) | (空) | **MagicMissile** | (空) | (空) | (空) | (空) |

**主枝/旁支结构：**
- Earth系: Prayer → Teleport(主) / MistFog(旁) → StoneEnchanted(主) / WrathOfGod(旁)
- Air系: Telekinesis → HolyLight(主) / Sacrifice(旁) → BallLightning(主) / ChainLightning(旁)
- Fire系: FireBall → Heal(主) / FireWalk(旁) → Meteor(主) / Armageddon(旁)
- Water系: FreezingSpear → PoisonCloud(主) / Fortuna(旁) → DarkRitual(主) / Nova(旁)

### 3.6 怪物系统 (monster_base.gd + 独立脚本)
- [x] 状态机（IDLE, CHASE, ATTACK, HURT, DEATH）
- [x] 追踪玩家（检测范围按怪物类型配置）
- [x] 近战攻击（攻击范围按怪物类型配置，冷却按怪物类型配置）
- [x] 受击闪烁（红色闪烁）
- [x] 死亡动画（0.25秒渐隐）
- [x] 经验值掉落
- [x] **数据驱动**：通过场景属性配置怪物参数（血量、速度、伤害、颜色等）
- [x] **独立脚本架构**：每个怪物有独立脚本
- [x] **AI行为更新**：每个怪物有独特的行为模式

**怪物配置（数据驱动，来自 monster_database.gd）：**
| 怪物 | 类型 | 基础血量 | 基础速度 | 基础伤害 | 检测范围 | 攻击范围 | min_distance | 攻击间隔 | 特殊行为 |
|------|------|---------|---------|---------|----------|----------|-------------|----------|----------|
| Troll | 近战 | 7/级 | 60 | 5 | **400** | **40** | 40 | 2.0s | 弱近战 |
| Spider | 近战 | 10/级 | 60 | 6 | **400** | **40** | 40 | 2.0s | 坚韧昆虫 |
| Demon | 近战 | 8/级 | 60 | 8 | **400** | **40** | 40 | 2.0s | 追击时速度+40% |
| Bear | 近战 | 9/级 | 65 | 10 | **400** | **40** | 40 | 2.0s | 强近战 |
| Mummy | 远程 | 4/级 | 65 | 4 | **500** | 150-300 | 150 | 2.0s | 射箭保持距离 |
| Reaper | 远程 | 10/级 | 60 | 4 | **500** | 150-340 | 150 | 5.0s | 3火焰魔法攻击 |
| Diablo | 远程 | 25/级 | 55 | 0 | **500** | 150-380 | 150 | 15.0s | 召唤其他怪物 |

**注意**：
- 近战怪物攻击范围 = min_distance = 40px（贴身才攻击）
- 远程怪物攻击范围 = 150-380px（保持距离射击）
- 检测范围：近战统一400px，远程统一500px
- 所有数值随等级和难度动态缩放

**怪物脚本架构：**
```
monster_base.gd (核心功能：移动、受击、死亡)
  ├── monster_melee.gd (近战行为：追击→攻击)
  │     ├── monster_spider.gd
  │     ├── monster_zombie.gd
  │     ├── monster_bear.gd
  │     ├── monster_demon.gd
  │     ├── monster_reaper.gd
  │     ├── monster_troll.gd
  │     └── monster_diablo.gd (Boss)
  └── monster_ranged.gd (远程行为：保持距离、射箭、逃跑转身)
        └── monster_mummy.gd (Archer，使用Mummy贴图)
```

### 3.7 怪物生成 (monster_spawner.gd / quest_monster_spawner.gd)
- [x] **统一边缘生成**：所有模式（Quest/Survival）怪物均从地图边缘生成
- [x] 安全边界（spawn_margin=80px），避免卡在墙里
- [x] 随机选择四边（上/右/下/左）生成
- [x] Survival：定时生成（间隔1秒），最大15只，含Boss生成逻辑
- [x] Quest：按波次生成（4/6/9只一组），所有波次完成后停止
- [x] 数据驱动：根据玩家等级和难度动态选择怪物类型和数值

### 3.8 掉落系统 (loot_manager.gd)
- [x] 5种稀有度（Common, Uncommon, Unique, Rare, Exceptional）
- [x] 12种物品类型（药水、卷轴、护盾、增益等）
- [x] 基础掉落率10%（受Fortuna技能影响）
- [x] 物品自动消失（10秒 lifetime）
- [x] 掉落物图标大小1.5倍（接近玩家大小）
- [x] 碰撞体积半径24（接近玩家32×32）

**掉落机制：**
1. 击败敌人 → 计算掉落概率（基础10% × Fortuna加成）
2. 决定是否掉落（randf() < 概率）
3. 根据稀有度权重选择物品类型：
   - Common(40%): 生命药水、法力药水
   - Uncommon(30%): 恢复药水、加速
   - Unique(15%): 经验书、魔法护盾
   - Rare(10%): 物理护盾、四倍伤害、免费施法
   - Exceptional(5%): 属性点、技能点、无敌

### 3.9 拾取物品 (pickup_item.gd)
- [x] 12种物品效果全部实现
- [x] 物品贴图加载（BonusXXX.png格式）
- [x] 接触自动拾取
- [x] Telekinesis被动：鼠标悬停自动拾取（带进度条显示）
- [x] 消失前1秒渐隐

### 3.10 HUD (hud.gd)
- [x] 生命值条（底部）
- [x] 法力值条
- [x] 经验值条
- [x] 等级显示
- [x] **Buff/Debuff 图标显示**（底部栏上方居中，带扇形冷却效果）

### 3.11 摄像机 (camera.gd)
- [x] 平滑跟随玩家
- [x] 缩放0.5（视野翻倍）

### 3.12 开发模式 (DevMode)
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
var hero_experience := 0                 # 当前经验（升级需要 hero_level * 200）
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
- `gain_experience(amount)` - 获得经验，自动处理升级（公式：hero_level * 200）
- `take_damage(amount, is_magic)` - 受到伤害（计算抗性）
- `heal(amount)` / `heal_over_time(amount, duration)` - 治疗
- `apply_strength/intelligence/etc()` - 属性变更后更新派生属性
- `activate_xxx(duration)` - 各种临时增益效果

### 4.2 经验值系统

**简化公式（2026-05-11更新）：**
```gdscript
# 升级所需经验 = 当前等级 × 200
var exp_to_next = hero_level * 200
```

**升级表：**
| 等级 | 需要经验 | 累积经验 |
|------|----------|----------|
| 1→2 | 200 | 200 |
| 2→3 | 400 | 600 |
| 3→4 | 600 | 1,200 |
| 4→5 | 800 | 2,000 |
| 5→6 | 1,000 | 3,000 |
| 10→11 | 2,000 | 11,000 |
| 20→21 | 4,000 | 42,000 |
| 50→51 | 10,000 | 255,000 |
| 100→101 | 20,000 | 1,010,000 |

**设计理由：**
- 原版公式前3级不规则（150, 450, 600），之后每级+200
- 简化后每级固定+200，更易理解和预测
- 与原版从第4级开始完全一致

---

## 5. Quest模式系统详解

### 5.1 概述
Quest模式是原版游戏的核心单人模式，玩家需要依次通过10个关卡。与Survival模式不同，Quest模式有明确的目标和终点。

### 5.2 Quest模式规则

| 特性 | Quest模式 | Survival模式 |
|------|-----------|--------------|
| 经验值 | 50%（减半） | 100% |
| 等级上限 | 每关最多升4级 | 无上限 |
| 通关条件 | 清除所有怪物 | 无（直到死亡） |
| 怪物生成 | 地图边缘，波次生成 | 地图边缘，持续生成 |
| 怪物行为 | 随机游荡 + 发现玩家后追击 | 随机游荡 + 发现玩家后追击 |
| 关卡数 | 10关线性推进 | 1张地图 |

### 5.3 关卡配置（10关）

| 关卡 | 名称 | 怪物总数 | 波次 | 怪物类型 |
|------|------|---------|------|---------|
| 1 | Ancient Way | 20 | [4,4,4,4,4] | spider, troll |
| 2 | Burned Land | 30 | [6,6,6,6,6] | spider, troll, bear |
| 3 | Desert Battle | 40 | [6×6,4] | spider, bear, mummy |
| 4 | Forgotten Dunes | 50 | [6×8,2] | bear, mummy, demon |
| 5 | Dark Swamp | 60 | [9×6,6] | mummy, demon, reaper |
| 6 | Skull Coast | 70 | [9×7,7] | demon, reaper, troll |
| 7 | Snowy Pass | 80 | [9×9,7] | reaper, troll, diablo |
| 8 | Hell Eye | 90 | [9×11] | troll, diablo |
| 9 | Inferno | 100 | [9×12,4] | demon, reaper, troll, diablo |
| 10 | Diablo's Lair | 120 | [9×15] | diablo, troll, reaper |

### 5.4 核心脚本

1. **`Scripts/Quest/quest_level_manager.gd`** — 关卡管理器
   - 管理10关的配置和进度
   - 处理等级上限检查（每关4级）
   - 检测通关条件（清除所有怪物）
   - 玩家死亡后返回主菜单

2. **`Scripts/Quest/quest_monster_spawner.gd`** — 怪物生成器
   - 从地图边缘生成怪物（安全边界100px）
   - 按波次生成（4/6/9只一组）
   - 所有波次完成后停止生成

3. **`Scripts/Quest/quest_hud_manager.gd`** — Quest专用HUD
   - 显示当前关卡名称和编号
   - 显示剩余怪物数量
   - 显示等级上限警告
   - 显示关卡完成/全部完成提示

4. **`Scripts/Monsters/monster_base.gd`** — 怪物基类（统一行为）
   - `wander_mode` 变量控制游荡行为（默认true，所有模式启用）
   - 墙壁反弹逻辑：碰到墙壁像光线反射一样反弹
   - 游荡速度 = 正常移动速度（非50%减速）
   - 未发现玩家时随机游荡，发现后追击

### 5.5 场景文件

- **`Scenes/QuestMain.tscn`** — Quest模式主场景
  - 地图大小：2560×2560
  - 玩家出生点：地图中心 **(1280, 1280)**
  - 包含 QuestLevelManager、QuestMonsterSpawner、QuestHUDManager

- **`Scenes/Main.tscn`** — Survival模式主场景
  - 地图大小：2560×2560
  - 玩家出生点：地图中心 **(1280, 1280)**（已统一）
  - 包含 MonsterSpawner、HUD

### 5.6 已知问题

1. **关卡解锁未持久化**：目前没有存档系统，每次游戏都从第1关开始
2. **地图背景单一**：10关使用相同的地面贴图
3. **Boss战未特殊设计**：Diablo关卡没有特殊的Boss机制
4. **通关奖励未实现**：通关后没有奖励结算画面

---

## 6. 技能系统完整说明

### 5.1 技能架构

每个技能独立 `.gd` 文件，包含：
- 静态配置: skill_name, base_cooldown, base_mana_cost, base_damage, damage_element
- 等级成长公式: get_mana_cost(level), get_damage(level), get_xxx(level)
- 施法入口: static func cast(hero, mouse_pos, skill_cooldowns) → bool

### 5.2 技能列表（21个）

| 技能 | 按键 | 元素 | 类型 | 说明 |
|------|------|------|------|------|
| Magic Missile | 鼠标左键 | basic | 投射物 | 追踪+加速+转弯减速 |
| Fireball | 鼠标右键 | fire | 投射物 | 直线飞行+爆炸AOE |
| Freezing Spear | Z | water | 投射物 | 直线穿透+冰冻效果 |
| Prayer | X | earth | 持续 | 扣血回蓝+蓝色粒子 |
| Heal | C | fire | 持续 | 持续回血+红色+号粒子 |
| Teleport | 2 | earth | 位移 | 位移到鼠标位置 |
| Mist Fog | 3 | earth | 区域 | 区域减速 |
| Wrath of God | 4 | earth | 全屏 | 全屏AOE |
| Telekinesis | Q | air | 被动 | 隔空取物（悬停拾取） |
| Sacrifice | R | air | 即时 | 消耗生命秒杀 |
| Holy Light | E | air | 射线 | 射线伤害 |
| Fire Walk | U | fire | 召唤 | 火焰轨迹 |
| Meteor | F | fire | 延迟AOE | 延迟AOE |
| Armageddon | G | fire | 全屏 | 全屏随机伤害 |
| Poison Cloud | H | water | 区域 | 区域持续伤害 |
| Nova | N | water | 自身AOE | 圆形AOE+冰冻 |
| Dark Ritual | B | water | 延迟 | 30%几率秒杀 |
| Stone Enchanted | 被动 | earth | 被动 | 被击石化反击 |
| Fortuna | V | water | 被动 | 增加掉落率 |
| Ball Lightning | I | air | 召唤 | 银球自动攻击附近敌人 |
| Chain Lightning | O | air | 投射物 | 闪电链弹跳3次 |

---

## 6. 已知问题与技术债务

### 6.1 当前问题
1. **高等级技能测试**：仅Magic Missile和Freezing Spear测试了高等级形态，其他21个技能高等级未充分测试
2. **怪物攻击冷却**：使用 `await` 可能导致协程问题
3. **没有音效**：所有技能目前没有音效（用户打算最后做）
4. **存档系统**：尚未实现
5. **地图系统**：原版有多张地图，目前只有一张测试地图
6. **Quest模式关卡解锁未持久化**：没有存档系统，每次从第1关开始
7. **Quest模式Boss战未特殊设计**：Diablo关卡没有特殊Boss机制
8. **Quest模式通关奖励未实现**：通关后没有奖励结算画面

### 6.2 技术债务
1. **projectile.gd**：旧版通用投射物逻辑，逐步弃用
2. **Monster.tscn**：旧版怪物场景，逐步被独立怪物场景替代
3. **技能数值平衡**：需要参考Excel文件进行详细调整

---

## 7. 开发路线图

### 已完成 ✅
- 核心战斗系统
- 21个技能独立重构
- 属性分配系统
- 8种怪物实现
- 掉落系统
- 开发模式
- 经验值公式简化
- **Quest模式基础系统** - 10关线性推进、波次生成、等级上限、边缘生成、游荡AI

### 待完成 🔧
1. **音效系统** - 为所有技能和事件添加音效
2. **存档系统** - 使用 FileAccess + JSON
3. **Quest模式完善** - 不同地图背景、更多关卡配置、Boss战设计、关卡解锁持久化
4. **UI完善** - 添加系别头像、更好的技能提示框等
5. **技能平衡** - 测试并调整技能数值
6. **性能优化** - 对象池、内存管理

---

## 8. 下一个Agent的工作建议

1. **先运行游戏**，按 F2 进入 DevMode，测试现有功能
2. **保持代码风格一致**：
   - snake_case 命名变量和函数
   - PascalCase 命名类名和节点名
   - UPPER_SNAKE_CASE 命名常量
3. **技能数值参考**：`E:\EvilInvasion\evil_invasion_spell.xlsx`
4. **节点命名规范**：参考 `NAMING_CONVENTIONS.md`

---

## 9. 关键代码文件索引

### 核心系统
1. `Scripts/global.gd` — 游戏全局状态（含经验值公式、Quest模式经验处理）
2. `Scripts/hero.gd` — 玩家控制与技能
3. `Scripts/game_mode_select.gd` — 游戏模式选择（Quest/Survival切换）

### 怪物系统
4. `Scripts/Monsters/monster_base.gd` — 怪物基类（含Quest模式游荡行为）
5. `Scripts/Monsters/monster_melee.gd` — 近战行为
6. `Scripts/Monsters/monster_ranged.gd` — 远程行为
7. `Scripts/Monsters/monster_database.gd` — 怪物数值数据库
8. `Scripts/loot_manager.gd` — 掉落管理器

### Quest模式系统
9. `Scripts/Quest/quest_level_manager.gd` — Quest关卡管理器（10关配置、等级上限）
10. `Scripts/Quest/quest_monster_spawner.gd` — Quest怪物生成器（边缘生成、波次）
11. `Scripts/Quest/quest_hud_manager.gd` — Quest专用HUD
12. `Scenes/QuestMain.tscn` — Quest模式主场景

### 存档系统
13. `Scripts/save_manager.gd` — 存档管理器（F5保存/F10读取，JSON格式）

### 技能系统
14. `Scripts/Spells/magic_missile.gd` — Magic Missile 技能（参考模板）

---

## 10. 用户偏好与注意事项

- 用户使用中文交流
- 用户会提供原版游戏截图作为参考
- 用户重视视觉还原度
- 用户要求"一个技能一个场景"的架构
- 用户喜欢做"tiny tweak"（微调），代码中应保留详细注释方便调整
- **经验值公式已简化为 `level * 200`**
- **Ball Lightning 和 Chain Lightning 是原版Air系技能，已实现**
- **存档快捷键**: F5保存, F10读取
- **受击恢复公式**: `hit_recovery = max(0.1, 0.5 - strength * 0.004)`
- **怪物生成模式**: 单个(1~3秒)/整排(18~22秒)/编组(8~12秒)/全边界(38~42秒, 需9级解锁)

---

**文档结束。祝开发顺利！**
