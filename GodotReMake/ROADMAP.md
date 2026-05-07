# Evil Invasion Remake — 完整开发路线图

> 基于 Godot 4.6 的 Evil Invasion (2006) 复刻项目
> 计划版本：v1.0 | 目标平台：Windows

---

## 目录

1. [项目概述](#1-项目概述)
2. [阶段零：当前状态](#2-阶段零当前状态)
3. [第一阶段：核心战斗系统](#3-第一阶段核心战斗系统)
4. [第二阶段：法术与物品系统](#4-第二阶段法术与物品系统)
5. [第三阶段：怪物体系与AI](#5-第三阶段怪物体系与ai)
6. [第四阶段：地图与关卡](#6-第四阶段地图与关卡)
7. [第五阶段：UI与菜单系统](#7-第五阶段ui与菜单系统)
8. [第六阶段：游戏模式与进度](#8-第六阶段游戏模式与进度)
9. [第七阶段：打磨与发布](#9-第七阶段打磨与发布)
10. [附录：原版游戏参数参考](#10-附录原版游戏参数参考)

---

## 1. 项目概述

### 1.1 游戏简介

Evil Invasion 是一款 2006 年发布的俯视角动作 RPG（Diablo-like），玩家扮演英雄，使用各种法术对抗不断涌来的怪物大军。复刻版将完全还原原版的核心玩法，并用 Godot 4 引擎重写全部代码。

### 1.2 目标

- **功能完整**：还原原版全部 20 种法术、8 种怪物、8+ 张地图、3 种难度
- **操作优化**：WASD 移动 + 鼠标瞄准（原版为纯鼠标操作）
- **画面提升**：保持原版风格但支持更高分辨率
- **跨平台**：Windows 为主，可扩展至 Linux/Mac

### 1.3 技术栈

| 组件 | 选择 |
|------|------|
| 引擎 | Godot 4.6 (GDScript) |
| 分辨率 | 1024×768（缩放保持） |
| 渲染 | 2D（视口拉伸） |
| 音频 | OGG Vorbis（复用原版） |
| 纹理 | PNG（原版 DDS 转换） |
| 数据格式 | JSON（平衡数据配置） |

---

## 2. 阶段零：当前状态

### 已完成 ✅

```
📁 GodotReMake/
├── project.godot              ← 项目配置文件
├── Scenes/
│   ├── Main.tscn              ← 主场景（地面 + 边界 + 怪物生成）
│   ├── Hero.tscn              ← 英雄（移动 + 瞄准 + 施法）
│   ├── Monster.tscn           ← 蜘蛛兵（AI 追踪 + 攻击 + 死亡）
│   ├── Projectile.tscn        ← 旧版通用投射物（逐步弃用）
│   ├── MagicMissile.tscn      ← ✅ Magic Missile 独立场景（追踪+加速+转弯减速）
│   ├── Fireball.tscn          ← ✅ Fireball 独立场景（爆炸AOE）
│   ├── FreezingSpear.tscn     ← ✅ Freezing Spear 独立场景（直线穿透+冰冻）
│   ├── Explosion.tscn         ← 爆炸特效
│   ├── PickupItem.tscn        ← 拾取物品
│   ├── HUD.tscn               ← 底部状态栏
│   ├── HeroPanel.tscn         ← 英雄面板（技能树+属性）
│   └── SkillButton.tscn       ← 技能按钮UI
├── Scripts/
│   ├── global.gd              ← 全局状态管理器
│   ├── hero.gd                ← 英雄控制（~990行，21个技能）
│   ├── monster.gd             ← 怪物 AI
│   ├── projectile.gd          ← 旧版通用投射物逻辑（逐步弃用）
│   ├── magic_missile.gd       ← ✅ Magic Missile 独立脚本
│   ├── fireball.gd            ← ✅ Fireball 独立脚本
│   ├── freezing_spear.gd      ← ✅ Freezing Spear 独立脚本
│   ├── explosion.gd           ← 爆炸动画
│   ├── pickup_item.gd         ← 拾取物品逻辑
│   ├── loot_manager.gd        ← 掉落管理器（Autoload）
│   ├── monster_spawner.gd     ← 怪物波次生成
│   ├── camera.gd              ← 相机跟随
│   ├── hud.gd                 ← HUD 数据绑定
│   ├── hero_panel.gd          ← 英雄面板逻辑
│   └── skill_button.gd        ← 技能按钮逻辑
└── Art/Placeholder/           ← 占位纹理（技能图标等）
```

### 当前可玩的特性

| 功能 | 按键 | 状态 |
|------|------|------|
| 英雄移动 | WASD | ✅ |
  | 英雄面向鼠标 | 鼠标移动 | ✅ |
  | Magic Missile（追踪+加速） | 鼠标左键 | ✅ 独立场景 + 独立脚本 |
  | Fireball（爆炸AOE） | 鼠标右键 | ✅ 独立场景 + 独立脚本 |
  | Freezing Spear（穿透+冰冻） | Z | ✅ 独立场景 + 独立脚本 |
  | 独立技能冷却（可同时施放） | - | ✅ |
  | 长按持续施法 | 按住按键 | ✅ |
  | 蜘蛛怪物追踪 AI | 自动 | ✅ |
  | 僵尸怪物追踪 AI | 自动 | ✅ |
  | 怪物攻击英雄 | 近战碰撞 | ✅ |
  | 杀怪得经验 | 自动 | ✅ |
  | 升级/属性增长 | 自动 | ✅ |
  | 技能树系统 | T | ✅ |
  | 属性分配系统 | T | ✅ |
  | DevMode（测试模式） | F2 | ✅ |
  | HUD 血/蓝/经验条 | 屏幕底部 | ✅ |
  | 相机跟随 | 自动 | ✅ |
  | 伤害类型系统（5种元素） | - | ✅ |

### 待解决的问题 🔧

- **18个技能仍使用旧版内联实现**，需要继续重构为独立场景 + 独立脚本（参考已完成的 3 个技能模式）
- 怪物攻击冷却使用 `await` 可能导致协程问题
- 需要扩展更多怪物种类（目前：蜘蛛、僵尸）
- 技能数据（冷却、伤害、法力消耗）已迁移至各技能脚本，hero.gd 仍需清理残留旧代码

---

## 3. 第一阶段：核心战斗系统

> **目标**：战斗手感流畅，英雄与怪物交互完整
> **预计时间**：3-5 天
> **难度**：⭐⭐

### 3.1 移动系统重构

```
当前问题：WASD + 鼠标瞄准耦合在一起

改为：
  - WASD → 屏幕坐标系上下左右（与鼠标方向解耦）
  - 鼠标 → 控制英雄朝向（旋转 Sprite）
  - 英雄始终面向鼠标方向移动
```

**文件**：`Scripts/hero.gd`

```gdscript
# 修改后的移动逻辑
func _physics_process(delta):
    # WASD 输入（屏幕方向，不受旋转影响）
    var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var target_velocity = input_dir * move_speed * Global.speed_multiplier
    velocity = velocity.move_toward(target_velocity, acceleration * delta)
    move_and_slide()
    
    # 鼠标瞄准（独立于移动方向）
    mouse_pos = get_global_mouse_position()
    sprite.rotation = global_position.angle_to_point(mouse_pos)
```

### 3.2 碰撞体系规范化

| 层级 | 名称 | 包含 |
|------|------|------|
| 1 | 墙壁 | StaticBody2D 边界 |
| 2 | 英雄 | CharacterBody2D (Hero) |
| 3 | 怪物 | CharacterBody2D (Monster) |
| 4 | 投射物 | Area2D (Projectile) |
| 5 | 道具 | Area2D (Item) |

**碰撞规则**：

| 检测方 | 检测层 | 用途 |
|--------|--------|------|
| 英雄(层2) | 掩码: 1+3 | 撞墙壁 + 撞怪物受伤 |
| 怪物(层3) | 掩码: 2 | 追踪英雄 |
| 投射物(层4) | 掩码: 3 | 击中怪物 |

### 3.3 受伤反馈系统

```
英雄受伤：
  - 屏幕边缘泛红（可选的 overlay）
  - 短暂无敌帧（0.5秒闪烁）
  - 血量低于 20% 时播放心跳音效

怪物受伤：
  - 精灵闪白（0.1秒）
  - 血条显示（Alt 键开关，默认打开）
  - 击退效果（被击中向后退）
```

### 3.4 死亡与重生

```gdscript
# global.gd
signal hero_died

# hero.gd
func _on_died():
    set_process(false)
    set_physics_process(false)
    # 播放死亡动画 → 2秒后弹出复活界面
    await get_tree().create_timer(2.0).timeout
    # 显示 "You Died" 面板，点击重试
    # respawn() 重置位置、血量、清除当前怪物
```

**产出物**：
- [ ] 解耦的 WASD 移动 + 鼠标瞄准
- [ ] 完整的碰撞层级表
- [ ] 受伤反馈（闪白/闪红/击退）
- [ ] 死亡与重生流程
- [ ] 无敌帧机制

---

## 4. 第二阶段：法术与物品系统

> **目标**：20 种法术 + 12 种物品完全可玩
> **预计时间**：7-10 天
> **难度**：⭐⭐⭐⭐

### 4.1 法术架构

```
技能架构（已重构为独立脚本模式）：

每个技能独立 .gd 文件，包含：
├── 静态配置: skill_name, base_cooldown, base_mana_cost, base_damage, damage_element
├── 等级成长公式: get_mana_cost(level), get_damage(level), get_xxx(level)
├── 施法入口: static func cast(hero, mouse_pos, skill_cooldowns) → bool
│
├── magic_missile.gd       ← ✅ 已重构（多发追踪）
├── fireball.gd            ← ✅ 已重构（爆炸AOE）
├── freezing_spear.gd      ← ✅ 已重构（穿透+冰冻）
├── prayer.gd              ← 待重构
├── teleport.gd            ← 待重构
├── mistfog.gd             ← 待重构
├── wrath_of_god.gd        ← 待重构
├── telekinesis.gd         ← 待重构
├── sacrifice.gd           ← 待重构
├── holy_light.gd          ← 待重构
├── heal.gd                ← 待重构
├── fire_walk.gd           ← 待重构
├── meteor.gd              ← 待重构
├── armageddon.gd          ← 待重构
├── poison_cloud.gd        ← 待重构
├── fortuna.gd             ← 待重构
├── dark_ritual.gd         ← 待重构
└── nova.gd                ← 待重构
```

**文件结构（当前实际结构）**：
```
Scripts/
├── magic_missile.gd        ← ✅ 已重构（静态配置 + cast 方法）
├── fireball.gd             ← ✅ 已重构（静态配置 + cast 方法）
├── freezing_spear.gd       ← ✅ 已重构（静态配置 + cast 方法）
├── hero.gd                 ← 英雄控制（技能调用入口， cooldown 管理）
├── monster.gd              ← 怪物 AI（状态机，数据驱动）
├── monster_spawner.gd      ← 怪物生成器
├── global.gd               ← 全局状态（skill_levels, mana, hp 等）
└── ... 其他系统脚本

Scenes/
├── MagicMissile.tscn       ← ✅ 独立场景
├── Fireball.tscn           ← ✅ 独立场景
├── FreezingSpear.tscn      ← ✅ 独立场景
├── Monster.tscn            ← 蜘蛛场景（共享 monster.gd）
├── Zombie.tscn             ← 僵尸场景（共享 monster.gd）
└── ... 其他场景
```

> 注：已放弃 SpellBase Resource 基类方案，改为每个技能独立 .gd 文件 + 静态方法的轻量模式。详见 `SPELL_DEVELOPMENT_GUIDE.md`。

### 4.2 法术效果实现分类

| 类型 | 实现方式 | 示例法术 |
|------|---------|---------|
| **投射物** | Area2D 沿方向飞行，命中后生成特效 | 火球、冰矛 |
| **即时命中** | 发射点到目标点的瞬间射线检测 | 闪电、圣光 |
| **地面 AOE** | 在目标位置生成区域 Area2D，持续伤害 | 毒云、陨石坑 |
| **自身范围** | 以英雄为中心的 CircleShape2D | 新星、神之愤怒 |
| **全屏** | 全屏闪烁 + 对所有怪物造成伤害 | 世界末日 |
| **位移** | 英雄瞬间移动到鼠标位置 | 传送 |
| **Buff/Heal** | 修改 Global 属性 + 特效 | 治疗、祈祷 |
| **Debuff** | 在怪物身上附加状态脚本 | 减速、石化 |
| **召唤** | 生成临时物体 | 火步留下的火焰 |
| **被动** | 常驻修改属性 | 幸运术、石肤术 |

### 4.3 法术冷却与快捷栏

```
法术槽位：
  ┌────┬────┬────┬────┬────┬────┬────┬────┐
  │ F1 │ F2 │ F3 │ F4 │ F5 │ F6 │ F7 │ F8 │
  ├────┼────┼────┼────┼────┼────┼────┼────┤
  │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │
  └────┴────┴────┴────┴────┴────┴────┴────┘
  
  鼠标左键 = 主法术
  鼠标右键 = 副法术
  数字键 1-8 = 切换法术到槽位
  
  快捷键：将法术拖拽到槽位
  冷却显示：槽位上有旋转遮罩
```

### 4.4 物品系统

```
ItemBase (Resource)
├── 属性: name, type, icon, duration, value
├── 方法: apply(hero) → void
├── 方法: remove(hero) → void  (仅限时效物品)

物品列表：
┌─────────────────────┬──────────┬──────────────┐
│ 物品               │ 类型     │ 效果         │
├─────────────────────┼──────────┼──────────────┤
│ Health Potion       │ 瞬间     │ +50 生命      │
│ Mana Potion         │ 瞬间     │ +50 法力      │
│ Rejuvenation        │ 瞬间     │ +50 生命+法力  │
│ Quad Damage         │ 时效30秒 │ 伤害×4        │
│ Physic Shield       │ 时效30秒 │ 物理伤害-50%  │
│ Magic Shield        │ 时效30秒 │ 魔法伤害-50%  │
│ Speed Boots         │ 时效30秒 │ 移速×1.5      │
│ Invulnerability     │ 时效10秒 │ 无敌           │
│ Free Spells         │ 时效30秒 │ 法术免费       │
│ Tome of Experience  │ 瞬间     │ +100 经验      │
│ Attribute Point     │ 永久     │ +5 属性点      │
│ Skill Point         │ 永久     │ +1 技能点      │
└─────────────────────┴──────────┴──────────────┘
```

**物品掉落机制**：
```
PROBABILITY_ITEM_LEVEL_1 = 基础掉率
PROBABILITY_ITEM_LEVEL_2 = 每级增加
...
PROBABILITY_ITEM_LEVEL_5 = 最高掉率

杀死怪物后 roll 掉率
支持同时掉落多个物品（低概率）
```

### 4.5 物品拾取与使用

```
物品掉落：
  - 怪物死亡时在位置生成 Area2D 物品
  - 英雄靠近（范围内）自动拾取
  - 拾取时播放拾取音效

物品使用：
  - 瞬间物品自动使用
  - 时效物品在 HUD 上显示 Buff 图标
  - 时效结束时自动移除效果
```

**产出物**：
- [ ] 20 个法术独立脚本
- [ ] 法术基类 Resource
- [ ] 法术快捷栏 UI
- [ ] 冷却显示系统
- [ ] 12 种物品脚本
- [ ] 物品掉落 + 自动拾取
- [ ] Buff 图标显示系统
- [ ] 平衡数值 JSON 配置文件

---

## 5. 第三阶段：怪物体系与 AI

> **目标**：8 种怪物各有特色 AI
> **预计时间**：5-7 天
> **难度**：⭐⭐⭐

### 5.1 怪物类型

| 怪物 | 行为 | 特殊 | 难度 | 状态 |
|------|------|------|------|------|
| **Spider** (蜘蛛) | 近战追踪，速度中等 | 无 | ⭐ | ✅ 已实现 |
| **Zombie** (僵尸) | 近战追踪，速度慢 | 低血量，低伤害，最弱怪 | ⭐ | ✅ 已实现 |
| **Bear** (熊) | 近战追踪，速度慢 | 高血量，高伤害 | ⭐⭐ | 待实现 |
| **Archer** (弓手) | 远程射击，保持距离 | 远程攻击 | ⭐⭐ | 待实现 |
| **Demon** (恶魔) | 快速追踪 | 高伤害 | ⭐⭐⭐ | 待实现 |
| **Reaper** (死神) | 中速追踪 | 法力燃烧 | ⭐⭐⭐ | 待实现 |
| **Rig** (骷髅) | 缓慢追踪 | 物理免疫/高抗性 | ⭐⭐ | 待实现 |
| **Boss** (首领) | 多种攻击模式 | 高血量+特殊技能 | ⭐⭐⭐⭐ | 待实现 |
| **Hero** (英雄单位) | — | NPC/剧情用 | — | 待实现 |

### 5.2 AI 行为树设计

```
每种怪物使用状态机：
                    ┌──────────┐
                    │   IDLE   │
                    └────┬─────┘
                         │ 发现英雄
                    ┌────▼─────┐
                    │  CHASE   │◄──────────────────┐
                    └────┬─────┘                   │
                         │ 进入攻击范围             │
                    ┌────▼──────┐                  │
                    │  ATTACK   │                  │
                    └────┬──────┘                  │
                         │ 超出范围/攻击结束         │
                    ┌────▼─────┐  被击中  ┌──────┐ │
                    │  CHASE   ├─────────►│ HURT├─┘
                    └──────────┘          └──┬───┘
                                             │ HP ≤ 0
                                        ┌────▼────┐
                                        │  DEATH  │
                                        └─────────┘
```

### 5.3 特殊能力实现

```gdscript
# Archer: 远程射击
func ranged_attack():
    var arrow = preload("res://Scenes/MonsterProjectile.tscn").instantiate()
    arrow.direction = global_position.direction_to(target.global_position)
    get_parent().add_child(arrow)
    # 然后后退保持距离

# Reaper: 法力燃烧
func mana_burn_attack():
    Global.mana -= 10.0  # 直接扣除法力
    Global.mana_changed.emit(Global.mana, Global.max_mana)

# Boss: 多阶段
func boss_phase_transition():
    if health < max_health * 0.5 and current_phase == 1:
        current_phase = 2
        move_speed *= 1.3
        attack_cooldown *= 0.7
        # 播放变身动画
```

### 5.4 怪物生成系统

```gdscript
# MonsterSpawner 升级
class WaveDefinition:
    var monsters: Array[PackedScene]
    var count: int
    var spawn_delay: float

# 按关卡配置波次
# 每波间隔 5 秒，清完进入下一波
# 生存模式：无限波次，逐渐增加难度
```

### 5.5 难度 scaling

```
普通难度：基础数值 × 1.0
硬核难度：基础数值 × 1.5，经验 × 1.2
噩梦难度：基础数值 × 2.5，经验 × 1.5，额外技能

按等级 scaling：
  怪物血量 = base_hp * (1 + level * 0.15)
  怪物伤害 = base_dmg * (1 + level * 0.10)
```

**产出物**：
- [x] 2 种怪物独立场景（Spider、Zombie，共享 monster.gd）
- [ ] 6 种怪物待实现
- [ ] 怪物远程攻击投射物
- [ ] 特殊能力（法力燃烧、多阶段Boss）
- [ ] 波次生成系统
- [ ] 难度 scaling 公式

---

## 6. 第四阶段：地图与关卡

> **目标**：8+ 张可游玩的关卡地图
> **预计时间**：7-10 天
> **难度**：⭐⭐⭐

### 6.1 原版地图列表

| 地图 | 风格 | 大小 | 特色 |
|------|------|------|------|
| AcientWay | 古道/废墟 | 中 | 直线通道 |
| DesertBattle | 沙漠 | 大 | 开阔地带，Archer 主场 |
| FogottenDunes | 遗忘沙丘 | 中 | 沙丘起伏 |
| HellsEye | 地狱之眼 | 小 | 圆形竞技场 |
| PoisonedSwamp | 剧毒沼泽 | 中 | 有毒地面 |
| SnowyPass | 雪域关隘 | 中 | 狭窄通道 |
| SkullsCoast | 骷髅海岸 | 大 | 海岸线 |
| BurnedLand | 焦灼之地 | 中 | 余烬效果 |

### 6.2 地图制作流程

```
1. 在 Godot 中使用 TileMap 绘制地图
   └── 目前用占位地面，后续替换为原版纹理

2. 每个地图是一个独立 Scene
   └── Scenes/Maps/
       ├── MapAcientWay.tscn
       ├── MapDesertBattle.tscn
       └── ...

3. 地图包含：
   - TileMap 层（地面 + 装饰）
   - StaticBody2D 碰撞边界
   - NavigationRegion2D（怪物寻路）
   - 英雄出生点（Marker2D）
   - 怪物生成区域
   - 关卡传送点（如果有）
```

### 6.3 关卡流程

```
选择关卡 → 加载地图 → 生成怪物 → 完成任务 → 传送/通关

任务类型：
  - "消灭所有怪物"（当前波次全部击杀）
  - "存活 X 秒"
  - "击杀 Boss"
  - "找到出口"

通关条件满足后：
  - 显示 "Gate Open" 提示
  - 出口处出现传送门
  - 英雄进入后结算
```

### 6.4 导航系统

```gdscript
# 使用 Godot NavigationRegion2D
# 怪物通过 NavigationAgent2D 寻路

func setup_navigation():
    var nav_region = $NavigationRegion2D
    nav_region.bake_navigation_polygon()
    
# 怪物 AI 升级：使用 NavigationAgent2D 代替直接追踪
func _physics_process(delta):
    if target and nav_agent.is_target_reachable():
        nav_agent.target_position = target.global_position
        var next_pos = nav_agent.get_next_path_position()
        velocity = global_position.direction_to(next_pos) * move_speed
    move_and_slide()
```

**产出物**：
- [ ] 8 张 TileMap 地图
- [ ] 地图切换系统（Scene 过渡）
- [ ] NavigationRegion2D 怪物寻路
- [ ] 关卡任务系统
- [ ] 传送门/出口机制

---

## 7. 第五阶段：UI 与菜单系统

> **目标**：完整的游戏界面
> **预计时间**：5-7 天
> **难度**：⭐⭐⭐

### 7.1 主菜单

```
┌─────────────────────────────────────┐
│        EVIL INVASION                │
│                                     │
│    [  New Game  ]                   │
│    [  Load Game  ]                  │
│    [  High Scores  ]                │
│    [  Options  ]                    │
│    [  Credits  ]                    │
│    [  Quit  ]                       │
│                                     │
│  ─────────────────────────────────  │
│  选择难度: Normal │ Hardcore │ Nightmare │
│  选择角色: [Profile Name]            │
└─────────────────────────────────────┘
```

**文件**：`Scenes/Menus/MainMenu.tscn`

### 7.2 英雄面板

```
按 H 键打开：
┌─────────────────────────────────────┐
│  Hero  Lv.10              [Close]   │
│                                     │
│  ┌──────────┐  HP: 280/280         │
│  │  Hero    │  MP: 150/150         │
│  │  Portrait│  EXP: 340/1000       │
│  └──────────┘                       │
│                                     │
│  属性 (剩余点数: 5):                │
│    Strength    12  [↑]  [+10 HP]    │
│    Dexterity   10  [↑]  [+2% SPD]   │
│    Stamina     10  [↑]  [+Regen]   │
│    Intelligence 8  [↑]  [+5 MP]    │
│    Wisdom       8  [↑]  [+Regen]   │
│                                     │
│  装备栏:                             │
│    [武器] [头盔] [盔甲] [饰品]       │
│                                     │
│  法术列表 (已学会 3/20):             │
│    [火球] [闪电] [治疗]              │
│                                     │
│  [升级说明] [操作指南]               │
└─────────────────────────────────────┘
```

**文件**：`Scenes/Menus/HeroPanel.tscn`

### 7.3 游戏内 HUD

```
┌──────────────────────────────────────┐
│                                      │
│         (游戏画面)                     │
│                                      │
│                                      │
├──────────────────────────────────────┤
│ Lv.10 ████████████░░ HP 280/280      │
│       ██████░░░░░░░░ MP 150/150      │
│       ████░░░░░░░░░░ EXP 340/1000    │
│                                      │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ │
│ │🔥│ │⚡│ │❄️│ │💫│ │🌟│ │💚│ │☣️│ │
│ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ │
│  1    2    3    4    5    6    7      │
│                                      │
│ [物品] [菜单]  WASD移动 鼠标瞄准      │
└──────────────────────────────────────┘
```

### 7.4 其他界面

| 界面 | 入口 | 功能 |
|------|------|------|
| Options | 主菜单 / 游戏中暂停 | 音量、按键设置、画面 |
| High Scores | 主菜单 | 本地 + 在线排行 |
| Credits | 主菜单 | 制作人员名单 |
| Pause Menu | 游戏中按 Esc | 继续 / 选项 / 返回主菜单 |
| Game Over | 英雄死亡 | 重试 / 返回主菜单 |
| Level Complete | 通关 | 评分 / 下一关 / 返回 |

### 7.5 按键设置

| 功能 | 默认键 |
|------|--------|
| 移动 | WASD |
| 主法术 (Magic Missile) | 鼠标左键 |
| 副法术 (Fireball) | 鼠标右键 |
| 法术 (Freezing Spear) | Z |
| 打开英雄面板 | T |
| 显示怪物血量 | Alt（按住） |
| 暂停 | Esc |
| 使用生命药水 | Q |
| 使用法力药水 | E |
| 使用四倍伤害 | R |
| DevMode（测试模式） | F2 |

**产出物**：
- [ ] 主菜单（新游戏/读档/设置/制作组）
- [ ] 英雄面板（属性加点/装备/法术列表）
- [ ] 暂停菜单
- [ ] 游戏结束界面
- [ ] 关卡完成界面
- [ ] 选项设置
- [ ] 高分榜
- [ ] 按键配置（可自定义）

---

## 8. 第六阶段：游戏模式与进度

> **目标**：完整的游戏循环
> **预计时间**：4-6 天
> **难度**：⭐⭐⭐

### 8.1 游戏模式

```
剧情模式 (Campaign)：
  8 张地图顺序推进
  每关任务：清怪 / 生存 / 击杀 Boss
  通关后解锁下一关

  地图树：
  古道 → 沙漠之战 → 遗忘沙丘 → 剧毒沼泽
     ↓                      ↓
  雪域关隘 ← 骷髅海岸 ← 焦灼之地 ← 地狱之眼

生存模式 (Survival)：
  单张地图，无限波次
  每 5 波出现一次 Boss
  记录生存波数 → 上传高分榜
```

### 8.2 存档系统

```gdscript
# 存档数据结构
{
    "version": "1.0",
    "profiles": [
        {
            "name": "HeroName",
            "level": 10,
            "experience": 340,
            "stats": {
                "strength": 12,
                "dexterity": 10,
                "stamina": 10,
                "intelligence": 8,
                "wisdom": 8
            },
            "unlocked_spells": ["fireball", "lightning", "heal"],
            "hotbar": ["fireball", "lightning", "", "", "", "", "", ""],
            "items": ["health_potion", "mana_potion"],
            "campaign_progress": 3,
            "survival_highscore": 15,
            "difficulty": "normal"
        }
    ]
}

# 文件位置：user://profiles.json
# 使用 Godot 的 FileAccess 读写
```

### 8.3 在线高分榜

原版使用 HTTP 上传到 `bin/ei_scores.php`，复刻版：

```
方案一：简单 JSON 文件（本地）
  - user://highscores.json
  - 按分数排序显示

方案二：HTTP 上传（需服务器）
  - 用 HTTPRequest 节点 POST 分数
  - 显示排行榜
```

### 8.4 经验与升级曲线

```
经验公式：
  升级所需经验 = level × 100
  
  每升一级：
  - 5 个属性点
  - 1 个技能点
  - +20 最大生命
  - +10 最大法力

属性加点效果：
  Strength (+1):  +10 生命上限
  Dexterity (+1): +2% 移动速度，+1% 闪避
  Stamina (+1):   +0.5/秒 生命恢复
  Intelligence (+1): +5 法力上限
  Wisdom (+1):   +0.3/秒 法力恢复
```

### 8.5 Profile 系统

```
支持多个存档 Profile：
  创建 → 输入名字 → 开始游戏
  读取 → 选择存档 → 继续

每个 Profile 独立：
  - 角色进度
  - 属性分配
  - 解锁的法术
  - 关卡进度
```

**产出物**：
- [ ] 剧情模式关卡链
- [ ] 生存模式无限波次
- [ ] 存档/读档系统
- [ ] 多 Profile 支持
- [ ] 在线/本地高分榜
- [ ] 经验与升级系统（细化）
- [ ] 3 种难度配置

---

## 9. 第七阶段：打磨与发布

> **目标**：商业级品质
> **预计时间**：7-14 天
> **难度**：⭐⭐⭐

### 9.1 资源替换

```
占位图 → 原版纹理：
  1. 从 Data.pak 提取 DDS 纹理
  2. 用工具（如 GIMP + DDS 插件）转换为 PNG
  3. 导入 Godot，生成 SpriteFrames
  
  优先级：
  P0: 英雄精灵 → 替换蓝色方块
  P0: 怪物精灵 → 替换红/棕色方块
  P0: 法术图标 → 替换法术槽位
  P1: 地面纹理 → 替换绿色占位图
  P1: UI 背景 → 替换纯色面板
  P2: 粒子贴图 → 增强法术特效

音效：
  - 直接从 Data.pak 提取 .ogg 文件
  - 导入 Godot 直接可用
  - 配置 AudioStreamPlayer2D
```

### 9.2 音效系统

```gdscript
# AudioManager (autoload)
# 管理所有音效的播放

enum Sfx {
    FIREBALL_CAST, FIREBALL_EXPLODE,
    LIGHTNING_CAST, LIGHTNING_STRIKE,
    HERO_HIT, HERO_DEATH,
    MONSTER_ATTACK, MONSTER_DEATH,
    ITEM_PICKUP, LEVEL_UP,
    BUTTON_CLICK, MENU_ROLL
}

func play_sfx(sfx: Sfx, position: Vector2 = Vector2.ZERO):
    var player = AudioStreamPlayer2D.new()
    player.stream = sfx_files[sfx]
    player.global_position = position
    player.finished.connect(player.queue_free)
    add_child(player)
    player.play()
```

### 9.3 视觉特效升级

```
法术特效：
  火球：ParticleSystem2D 拖尾粒子 + 爆炸圆形扩散
  闪电：Line2D 锯齿效果 + 光晕
  陨石：下落粒子 + 爆炸 + 地面燃烧区域
  新星：圆形扩散波
  传送：英雄位置扭曲效果
  治疗：绿色十字升起
  毒云：紫色雾气区域

通用特效：
  升级：金色光柱
  拾取物品：闪烁圆环
  怪物死亡：消散粒子
  关卡完成：烟花效果
```

### 9.4 性能优化

```
目标：60 FPS，同时 50+ 怪物

优化方案：
  1. 使用 Object pooling（对象池）复用子弹/怪物
  2. 远处怪物使用 LOD（简化 AI 更新频率）
  3. TileMap 替代大量独立 Sprite
  4. 粒子数量控制在合理范围
  5. 使用 VisibleOnScreenNotifier2D 禁用屏幕外怪物
  6. CanvasItem 的 visible 控制

对象池示例：
  class ObjectPool:
      var scene: PackedScene
      var pool: Array[Node] = []
      func get(): 
          if pool.is_empty(): return scene.instantiate()
          else: return pool.pop_back()
      func release(obj): obj.hide(); pool.push_back(obj)
```

### 9.5 打包与发布

```
Godot 导出模板：
  Windows (x86_64)：
    - 导出为 .exe
    - 包含 .pck 资源包
    - 可选：用 rcedit 修改图标

打包大小预估：
  代码 + 场景：~5 MB
  占位纹理：~1 MB
  原版音效 (OGG)：~20 MB
  原版纹理 (PNG)：~30 MB
  总大小：~56 MB

发布渠道：
  - itch.io
  - GitHub Releases
  - 本地分享
```

### 9.6 测试清单

```
功能测试：
  [ ] 所有 20 种法术施放正常
  [ ] 所有 8 种怪物行为正常
  [ ] 8 张地图无碰撞漏洞
  [ ] 存档/读档完整
  [ ] 3 种难度数值正确
  [ ] 生存模式无尽波次

性能测试：
  [ ] 50+ 怪物保持 60 FPS
  [ ] 大量投射物无卡顿
  [ ] 内存无泄漏

兼容性测试：
  [ ] Windows 10/11
  [ ] 不同分辨率显示正常
  [ ] 键盘鼠标组合键无冲突
```

**产出物**：
- [ ] 原版资源导入完成
- [ ] 完整的音效系统
- [ ] 视觉特效增强
- [ ] 性能优化（对象池）
- [ ] 导出包
- [ ] 测试报告

---

## 10. 附录：原版游戏参数参考

> 以下参数来自对原版 Logic.dll 的字符串分析和 Data.pak 结构推测，部分为估算值。

### 10.1 英雄基础属性

```
STRENGTH (力量):
  STRENGTH_ON_HEALTH:     每点 +10 HP
  STRENGTH_ON_HIT_RECOVERY: 减少受击硬直

DEXTERITY (敏捷):
  DEXTERITY_ON_SPEED:        每点 +2% 移动速度
  DEXTERITY_ON_CHANCE_TO_BE_HIT: 增加闪避

STAMINA (耐力):
  STAMINA_ON_HEALTH_REGENERATION: 增加 HP 恢复速度
  STAMINA_ON_SPEED:                 少量移速加成

INTELLIGENCE (智力):
  INTELLIGENCE_ON_MANA:             每点 +5 MP
  INTELLIGENCE_ON_MANA_REGENERATION: 增加 MP 恢复

WISDOM (智慧):
  WISDOM_ON_MANA:             少量 MP 加成
  WISDOM_ON_MANA_REGENERATION: MP 恢复加成
```

### 10.2 法术参考数值（估算）

```
法术           | 法力  | 冷却  | 基础伤害
───────────────|───────|───────|────────
火球术         | 10    | 0.3s  | 15-25
闪电术         | 20    | 0.5s  | 25-40
治疗术         | 15    | 1.0s  | +30 HP
陨石术         | 35    | 1.5s  | 50-80
新星术         | 25    | 0.8s  | 20-35
毒云术         | 20    | 1.0s  | 10/秒 (持续)
传送术         | 15    | 2.0s  | —
神之愤怒       | 50    | 3.0s  | 100-150
世界末日       | 60    | 5.0s  | 150-200
```

### 10.3 怪物参考数值

```
怪物   | HP   | 伤害 | 速度 | 经验
───────|──────|──────|──────|─────
蜘蛛   | 30   | 5    | 80   | 15
熊     | 80   | 12   | 50   | 30
弓手   | 25   | 8    | 70   | 20
恶魔   | 50   | 15   | 110  | 35
死神   | 40   | 10   | 90   | 25
骷髅   | 60   | 7    | 40   | 20
Boss   | 500  | 30   | 60   | 200
```

### 10.4 物品参考数值

```
物品            | 持续时间 | 效果值
────────────────|─────────|───────
Health Potion   | 瞬间    | +50 HP
Mana Potion     | 瞬间    | +50 MP
Rejuvenation    | 瞬间    | +50 HP + 50 MP
Quad Damage     | 30s     | 伤害 ×4
Physic Shield   | 30s     | -50% 物理伤害
Magic Shield    | 30s     | -50% 魔法伤害
Speed Boots     | 30s     | 移速 ×1.5
Invulnerability | 10s     | 无敌
Free Spells     | 30s     | 0 法力消耗
Tome of Exp     | 瞬间    | +100 经验
```

### 10.5 原版 PAK 文件结构参考

```
文件头: "Ver 1.0.k" (10字节)
TOC: 从偏移16开始
  每条目: 文件名(null结尾) + 4字节偏移 + 2字节大小 + 2字节填充
数据: 从 TOC 结束后开始
  文本文件(.txt .fnt): XOR 0xA5 加密
  音频(.ogg) + 纹理(.dds .jpg .raw): 原始存储

已知 TOC 条目数量: 107 个文件
数据总大小: ~15 MB

脚本数据文件（加密方式暂未破解）：
  Scripts/HeroBalance.txt        ← 英雄平衡
  Scripts/MonsterBalance.txt     ← 怪物属性
  Scripts/SpellBalance.txt       ← 法术数值
  Scripts/ItemBalance.txt        ← 物品数值
  Scripts/MapDesc.txt            ← 地图描述
  Scripts/HeroDesc.txt           ← 英雄描述
  Scripts/SpellDesc.txt          ← 法术描述
  Scripts/UnitAnimDesc.txt       ← 单位动画描述
```

---

## 里程碑时间线

```
Phase 0: Demo 可用                    ✅ 已完成
Phase 1: 核心战斗系统                  🔧 当前阶段 (3-5天)
  ├── ✅ 3个技能独立重构完成（Magic Missile、Fireball、Freezing Spear）
  ├── ✅ 独立冷却系统（每个技能各自冷却，可同时施放）
  ├── ✅ 长按持续施法
  ├── ✅ 技能数据迁移至各技能脚本
  ├── ✅ 2种怪物实现（Spider、Zombie）
  └── 🔄 待完成：18个旧技能重构、受伤反馈、死亡重生
Phase 2: 法术与物品系统                7-10天
Phase 3: 怪物体系与 AI                5-7天
Phase 4: 地图与关卡                   7-10天
Phase 5: UI 与菜单系统                5-7天
Phase 6: 游戏模式与进度               4-6天
Phase 7: 打磨与发布                   7-14天

总计：约 38-59 天（1.5-2 个月全职开发）
```

---

> 本文档会随项目进展持续更新。
> 最后更新：2026-05-07
