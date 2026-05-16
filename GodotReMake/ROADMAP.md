# Evil Invasion Remake — 完整开发路线图

> 基于 Godot 4.6 的 Evil Invasion (2006) 复刻项目
> 计划版本：v1.0 | 目标平台：Windows
> **最后更新：2026-05-16（v12 Agent: hero.gd全面重构 + 统一施法调度 + 冷却缩减遗物修正 + 全项目性能优化）**

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

- **功能完整**：还原原版全部 21 种法术、8 种怪物、8+ 张地图、3 种难度
- **操作优化**：WASD 移动 + 鼠标瞄准（原版为纯鼠标操作）
- **画面提升**：保持原版风格但支持更高分辨率
- **跨平台**：Windows 为主，可扩展至 Linux/Mac

### 1.3 技术栈

| 组件 | 选择 |
|------|------|
| 引擎 | Godot 4.6 (GDScript) |
| 分辨率 | 1024×960（v8: 从 768 增加到 960，底部 HUD 86px + 游戏视口 874px） |
| 渲染 | 2D |
| 音频 | OGG Vorbis（68个音效已从原版提取） |
| 纹理 | PNG（原版 DDS 已转换，贴图已从 Data.pak 提取并合成） |
| 数据格式 | JSON（平衡数据配置） |

---

## 2. 阶段零：当前状态

### 2.1 项目结构（2026-05-13 更新）

```
GodotReMake/
├── project.godot              ← 项目配置文件
├── Scenes/
│   ├── Main.tscn              ← 主场景（地面 + 边界 + 怪物生成）
│   ├── Hero.tscn              ← 英雄（移动 + 瞄准 + 施法）
│   ├── Troll.tscn             ← Troll场景
│   ├── Spider.tscn            ← 蜘蛛场景
│   ├── Bear.tscn              ← 熊场景
│   ├── Mummy.tscn             ← 木乃伊/弓手场景
│   ├── Reaper.tscn            ← 死神场景
│   ├── Demon.tscn             ← 恶魔场景
│   ├── Diablo.tscn            ← 特殊怪物场景
│   ├── MonsterArrow.tscn      ← 怪物弓箭投射物
│   ├── Projectile.tscn        ← 旧版通用投射物（逐步弃用）
│   ├── MagicMissile.tscn      ← Magic Missile 独立场景
│   ├── Fireball.tscn          ← Fireball 独立场景
│   ├── FreezingSpear.tscn     ← Freezing Spear 独立场景
│   ├── Prayer.tscn            ← Prayer 独立场景
│   ├── Heal.tscn              ← Heal 独立场景
│   ├── Teleport.tscn          ← Teleport 独立场景
│   ├── MistFog.tscn           ← Mist Fog 独立场景
│   ├── WrathOfGod.tscn        ← Wrath of God 独立场景
│   ├── HolyLight.tscn         ← Holy Light 独立场景
│   ├── FireWalk.tscn          ← Fire Walk 独立场景
│   ├── Meteor.tscn            ← Meteor 独立场景
│   ├── MeteorSingle.tscn      ← 单颗陨石子场景
│   ├── Armageddon.tscn        ← Armageddon 独立场景
│   ├── ArmageddonZone.tscn    ← Armageddon 区域子场景
│   ├── PoisonCloud.tscn       ← Poison Cloud 独立场景
│   ├── Nova.tscn              ← Nova 独立场景
│   ├── NovaProj.tscn          ← Nova 投射物子场景
│   ├── DarkRitual.tscn        ← Dark Ritual 独立场景
│   ├── BallLightning.tscn     ← Ball Lightning 独立场景
│   ├── ChainLightningProj.tscn ← Chain Lightning 投射物场景
│   ├── Explosion.tscn         ← 爆炸特效
│   ├── PickupItem.tscn        ← 拾取物品
│   ├── HUD.tscn               ← 底部状态栏（瘦底栏+通栏经验条）
│   ├── HeroPanel.tscn         ← 英雄面板（技能树+属性）
│   ├── SkillButton.tscn       ← 技能按钮UI
│   ├── BuffIcon.tscn          ← Buff图标
│   ├── GameModeSelect.tscn    ← 游戏模式选择
│   ├── LevelSelect.tscn       ← Quest关卡选择器
│   ├── QuestMain.tscn         ← Quest模式主场景
│   ├── PauseMenu.tscn         ← 暂停菜单（ESC打开）
│   ├── GameOverScreen.tscn    ← 死亡画面覆盖层
│   ├── LevelCompleteScreen.tscn ← 关卡完成画面
│   └── VictoryScreen.tscn     ← 全通通关画面
├── Scripts/
│   ├── global.gd              ← 全局状态管理器
│   ├── hero.gd                ← 英雄控制（技能调用入口，cooldown 管理）
│   ├── object_pool.gd         ← 对象池（Autoload，v7新增）
│   ├── projectile.gd          ← 通用投射物逻辑（已对象池化）
│   ├── explosion.gd           ← 爆炸动画
│   ├── pickup_item.gd         ← 拾取物品逻辑
│   ├── loot_manager.gd        ← 掉落管理器（Autoload）
│   ├── monster_spawner.gd     ← 怪物波次生成（支持多种怪物）
│   ├── camera.gd              ← 相机跟随
│   ├── hud.gd                 ← HUD 数据绑定（含伤害红晕shader）
│   ├── hero_panel.gd          ← 英雄面板逻辑
│   ├── skill_button.gd        ← 技能按钮逻辑
│   ├── buff_icon.gd           ← Buff图标逻辑
│   ├── pause_menu.gd          ← 暂停菜单逻辑
│   ├── game_over_screen.gd    ← 死亡画面逻辑
│   ├── level_complete_screen.gd ← 关卡完成画面逻辑
│   ├── victory_screen.gd      ← 通关画面逻辑
│   ├── cooldown_overlay.gd    ← 技能冷却扇形遮罩控件
│   ├── save_manager.gd        ← 存档管理器
│   ├── level_select.gd        ← 关卡选择器逻辑
│   ├── game_mode_select.gd    ← 游戏模式选择逻辑
│   ├── Spells/                ← 技能脚本目录（21个）
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
│   │   ├── fire_walk.gd
│   │   ├── meteor.gd
│   │   ├── meteor_single.gd
│   │   ├── armageddon.gd
│   │   ├── armageddon_zone.gd
│   │   ├── poison_cloud.gd
│   │   ├── fortuna.gd
│   │   ├── dark_ritual.gd
│   │   ├── nova.gd
│   │   ├── nova_proj.gd
│   │   ├── stone_enchanted.gd
│   │   ├── ball_lightning.gd
│   │   ├── chain_lightning.gd
│   │   ├── chain_lightning_proj.gd
│   │   ├── explosion.gd
│   │   ├── projectile.gd
│   │   └── skill_button.gd
│   ├── Monsters/              ← 怪物脚本目录（7种）
│   │   ├── monster_base.gd
│   │   ├── monster_melee.gd
│   │   ├── monster_ranged.gd
│   │   ├── monster_troll.gd
│   │   ├── monster_spider.gd
│   │   ├── monster_bear.gd
│   │   ├── monster_mummy.gd
│   │   ├── monster_reaper.gd
│   │   ├── monster_demon.gd
│   │   ├── monster_diablo.gd
│   │   ├── monster_arrow.gd
│   │   └── monster_database.gd
│   └── Quest/                 ← Quest模式相关脚本
│       ├── quest_level_manager.gd
│       ├── quest_monster_spawner.gd
│       ├── quest_hud_manager.gd
│       └── test_quest.gd
└── Art/Placeholder/           ← 占位纹理（技能图标等）
```

### 2.2 当前可玩的特性（2026-05-13 更新）

| 功能 | 按键 | 状态 |
|------|------|------|
| 英雄移动 | WASD | ✅ |
| 英雄面向鼠标 | 鼠标移动 | ✅ |
| Magic Missile（追踪+加速） | 鼠标左键 | ✅ 独立场景 + 独立脚本 |
| Fireball（爆炸AOE） | 鼠标右键 | ✅ 独立场景 + 独立脚本 |
| Freezing Spear（穿透+冰冻） | Z | ✅ 独立场景 + 独立脚本 |
| Prayer（持续扣血回蓝） | X | ✅ 独立场景 + 独立脚本 |
| Heal（持续回血） | C | ✅ 独立场景 + 独立脚本 |
| Teleport（位移） | 2 | ✅ 独立场景 + 独立脚本 |
| Mist Fog（区域减速） | 3 | ✅ 独立场景 + 独立脚本 |
| Wrath of God（全屏AOE） | 4 | ✅ 独立场景 + 独立脚本 |
| Telekinesis（隔空取物） | Q | ✅ 独立脚本 |
| Sacrifice（消耗生命秒杀） | R | ✅ 独立脚本 |
| Holy Light（射线伤害） | E | ✅ 独立场景 + 独立脚本 |
| Fire Walk（火焰轨迹） | U | ✅ 独立场景 + 独立脚本 |
| Meteor（延迟AOE） | F | ✅ 独立场景 + 独立脚本 |
| Armageddon（全屏随机伤害） | G | ✅ 独立场景 + 独立脚本 |
| Poison Cloud（区域持续伤害） | H | ✅ 独立场景 + 独立脚本 |
| Fortuna（被动掉率） | V | ✅ 独立脚本 |
| Dark Ritual（延迟秒杀） | B | ✅ 独立场景 + 独立脚本 |
| Nova（自身圆形AOE） | N | ✅ 独立场景 + 独立脚本 |
| Stone Enchanted（被动石化） | 被动 | ✅ 独立脚本 |
| Ball Lightning（银球自动攻击） | I | ✅ 独立场景 + 独立脚本 |
| Chain Lightning（闪电链弹跳） | O | ✅ 独立场景 + 独立脚本 |
| 独立技能冷却（可同时施放） | - | ✅ |
| 长按持续施法 | 按住按键 | ✅ |
| 技能数据封装（各技能脚本管理自身数据） | - | ✅ |
| 7种怪物 AI（各有独特行为） | 自动 | ✅ |
| 怪物数据驱动（通过场景属性配置） | - | ✅ |
| 怪物攻击英雄 | 近战碰撞 | ✅ |
| 杀怪得经验 | 自动 | ✅ |
| 升级/属性增长 | 自动 | ✅ |
| 经验值公式（简化：level * 200） | - | ✅ |
| 技能树系统 | T | ✅ |
| 属性分配系统 | T | ✅ |
| DevMode（测试模式） | F2 | ✅ |
| HUD 血/蓝/经验条（瘦底栏+通栏经验条） | 屏幕底部 | ✅ |
| Buff/Debuff 图标显示 | 底部栏上方 | ✅ |
| 相机跟随 | 自动 | ✅ |
| 伤害类型系统（5种元素） | - | ✅ |
| 掉落系统（12种物品） | - | ✅ |
| Telekinesis悬停拾取 | 鼠标悬停 | ✅ |
| Quest模式基础系统 | - | ✅ |
| 统一怪物生成（边缘生成） | - | ✅ |
| 统一怪物游荡（墙壁反弹） | - | ✅ |
| 统一英雄出生点 | - | ✅ |
| **暂停菜单（PauseMenu）** | ESC | ✅ 含Resume/Save/Load/Return/Quit |
| **死亡画面（GameOverScreen）** | 死亡触发 | ✅ 显示统计+Retry/Return |
| **关卡完成画面（LevelCompleteScreen）** | 通关触发 | ✅ 统计+Continue |
| **通关画面（VictoryScreen）** | 全10关通关 | ✅ 祝贺+Return to Menu |
| **技能栏冷却显示** | 自动 | ✅ 灰色扇形遮罩 |
| **怪物信息切换（Alt键）** | 左Alt | ✅ 血条+伤害数字显示/隐藏 |
| **受击红晕（Damage Vignette）** | 血量<50% | ✅ 径向渐变红色边缘效果 |
| **存档系统** | F5保存/F10读取 | ✅ JSON格式 |
| **受击恢复系统** | 被攻击触发 | ✅ 不能施法+减速20% |
| **快捷槽位系统（4槽位）** | LMB/RMB/Shift/Space | ✅ Shift+左键/Space+左键分配 + 存档持久化 |
| **Controls Guide 操作指南** | 主菜单/暂停菜单 | ✅ 快捷键说明浏览 |
| **Firewalk Toggle 重写** | U | ✅ toggle类技能，移动产生火焰DOT |
| **爆炸伤害碰撞检测** | 自动 | ✅ 所有范围技能使用物理碰撞检测 |
| **Teleport 输入修复** | 2 | ✅ 修复按"2"键无效（v12在 _process 中处理） |
| **暂停时设置 Quickslot** | T+鼠标 | ✅ HeroPanel暂停时仍可设置 |
| **Meteor/Armageddon 平衡** | F/G | ✅ 调整生成间隔/数量/贴图大小 |
| **Autocast 间隔优化** | 右键设置 | ✅ 0.15s→0.1s |
| **游戏导出配置准备** | - | ✅ export_presets.cfg 已配置加密参数，已成功导出加密版单 exe |
| **统一施法调度** | - | ✅ 全部21个 cast_xxx() 合并为 _cast_skill(skill_id)，删除 ~200 行重复代码 |
| **技能输入检测去重** | - | ✅ 移除 _unhandled_input()，消除双重输入检测 |
| **冷却缩减遗物修正** | - | ✅ 从"减慢冷却"改为"技能加速"，并影响自动火球/护盾充能 |
| **全局代码清理** | 12文件 | ✅ 移除60+条遗留 print 调试语句 |
| **HUD性能优化** | hud.gd | ✅ StyleBoxFlat缓存 + 冷却UI节流（10次/秒代替60次/秒） |
| **击退遗物修复** | magic_missile.gd | ✅ 方向修正为弹道方向，速度100px/s实现50px击退效果 |
| **Quickslot修正** | hero.gd, global.gd | ✅ 死亡重置清空，Shift/Space无默认技能 |
| **Dev按钮位置修复** | HeroPanel.tscn | ✅ 按钮宽度从200缩至110px，避免超出面板 |

### 2.3 待解决的问题 🔧

| 问题 | 优先级 | 说明 |
|------|--------|------|
| 怪物寻路 | P1 | 目前直接追踪玩家，无 NavigationRegion2D 寻路 |
| 怪物特殊能力 | P1 | 部分怪物特殊能力标注为"待实现"（如Bear冲锋、Spider毒液） |
| Quest模式关卡解锁持久化 | P1 | 当前Quest进度未持久化保存 |
| 高分榜 | P2 | 无本地/在线排行 |
| 多 Profile | P2 | 仅支持单存档 |
| 选项设置 | P2 | 音量/按键自定义/画面设置（优先级低） |
| 怪物碰撞伤害 | P2 | 怪物碰撞英雄时造成伤害，但无碰撞冷却 |
| 地图纹理 | P3 | 6张 DDS 地图纹理已提取，最后做（纯美术资源） |
| 音效缺失 | P3 | 68个OGG已提取，最后做（纯音频资源） |

---

## 3. 第一阶段：核心战斗系统

> **目标**：战斗手感流畅，英雄与怪物交互完整
> **预计时间**：3-5 天
> **难度**：⭐⭐
> **状态**：✅ 已完成

### 3.1 移动系统

```
已实现：
  - WASD → 屏幕坐标系上下左右（与鼠标方向解耦）
  - 鼠标 → 控制英雄朝向（旋转 Sprite）
  - 英雄始终面向鼠标方向
```

**文件**：`Scripts/hero.gd`

```gdscript
# 当前移动逻辑
func _physics_process(delta):
    var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var target_velocity = input_dir * get_move_speed() * Global.speed_multiplier
    velocity = velocity.move_toward(target_velocity, acceleration * delta)
    move_and_slide()
    
    mouse_pos = get_global_mouse_position()
    sprite.rotation = global_position.angle_to_point(mouse_pos)
```

### 3.2 碰撞体系

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
已实现：
英雄受伤：
  - 受击恢复状态（0.5秒，不能施法，移速降低20%）
  - 受击减速debuff

怪物受伤：
  - 精灵闪红（0.1秒）
  - 死亡动画（16帧 Death spritesheet，~1.28秒后自动销毁）
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
- [x] 解耦的 WASD 移动 + 鼠标瞄准
- [x] 完整的碰撞层级表
- [x] 受伤反馈（闪红）
- [x] 死亡与重生流程
- [x] 无敌帧机制（通过 invulnerable 变量）

---

## 4. 第二阶段：法术与物品系统

> **目标**：21 种法术 + 12 种物品完全可玩
> **预计时间**：7-10 天
> **难度**：⭐⭐⭐⭐
> **状态**：✅ 已完成

### 4.1 法术架构

```
技能架构（已重构为独立脚本模式）：

每个技能独立 .gd 文件，包含：
├── 静态配置: skill_name, base_cooldown, base_mana_cost, base_damage, damage_element
├── 等级成长公式: get_mana_cost(level), get_damage(level), get_xxx(level)
├── 施法入口: static func cast(hero, mouse_pos, skill_cooldowns) → bool
│
├── magic_missile.gd       ← ✅ 已重构
├── fireball.gd            ← ✅ 已重构
├── freezing_spear.gd      ← ✅ 已重构
├── prayer.gd              ← ✅ 已重构
├── teleport.gd            ← ✅ 已重构
├── mistfog.gd             ← ✅ 已重构
├── wrath_of_god.gd        ← ✅ 已重构
├── telekinesis.gd         ← ✅ 已重构
├── sacrifice.gd           ← ✅ 已重构
├── holy_light.gd          ← ✅ 已重构
├── heal.gd                ← ✅ 已重构
├── fire_walk.gd           ← ✅ 已重构
├── meteor.gd              ← ✅ 已重构
├── armageddon.gd          ← ✅ 已重构
├── poison_cloud.gd        ← ✅ 已重构
├── fortuna.gd             ← ✅ 已重构
├── dark_ritual.gd         ← ✅ 已重构
├── nova.gd                ← ✅ 已重构
├── stone_enchanted.gd     ← ✅ 已重构
├── ball_lightning.gd      ← ✅ 已重构（原版Air系技能）
└── chain_lightning.gd     ← ✅ 已重构（原版Air系技能）
```

**文件结构（当前实际结构）**：
```
Scripts/Spells/
├── magic_missile.gd        ← ✅ 已重构
├── fireball.gd             ← ✅ 已重构
├── freezing_spear.gd       ← ✅ 已重构
├── prayer.gd               ← ✅ 已重构
├── heal.gd                 ← ✅ 已重构
├── teleport.gd             ← ✅ 已重构
├── mistfog.gd              ← ✅ 已重构
├── wrath_of_god.gd         ← ✅ 已重构
├── telekinesis.gd          ← ✅ 已重构
├── sacrifice.gd            ← ✅ 已重构
├── holy_light.gd           ← ✅ 已重构
├── fire_walk.gd            ← ✅ 已重构
├── meteor.gd               ← ✅ 已重构
├── armageddon.gd           ← ✅ 已重构
├── poison_cloud.gd         ← ✅ 已重构
├── fortuna.gd              ← ✅ 已重构
├── dark_ritual.gd          ← ✅ 已重构
├── nova.gd                 ← ✅ 已重构
├── stone_enchanted.gd      ← ✅ 已重构
├── ball_lightning.gd       ← ✅ 已重构
└── chain_lightning.gd      ← ✅ 已重构
```

> 注：已放弃 SpellBase Resource 基类方案，改为每个技能独立 .gd 文件 + 静态方法的轻量模式。详见 `SPELL_DEVELOPMENT_GUIDE.md`。

### 4.2 法术效果实现分类

| 类型 | 实现方式 | 示例法术 |
|------|---------|---------|
| **投射物** | Area2D 沿方向飞行，命中后生成特效 | 火球、冰矛 |
| **即时命中** | 发射点到目标点的瞬间射线检测 | 圣光、牺牲 |
| **地面 AOE** | 在目标位置生成区域 Area2D，持续伤害 | 毒云、陨石坑 |
| **自身范围** | 以英雄为中心的 CircleShape2D | 新星、神之愤怒 |
| **全屏** | 全屏闪烁 + 对所有怪物造成伤害 | 世界末日 |
| **位移** | 英雄瞬间移动到鼠标位置 | 传送 |
| **Buff/Heal** | 修改 Global 属性 + 特效 | 治疗、祈祷 |
| **Debuff** | 在怪物身上附加状态脚本 | 减速、石化 |
| **召唤** | 生成临时物体 | 火步留下的火焰、球状闪电 |
| **被动** | 常驻修改属性 | 幸运术、石肤术 |

### 4.3 法术冷却与快捷栏

```
已实现：
- 每个技能独立冷却（skill_cooldowns 字典管理）
- 可同时施放多个技能
- 长按持续施法
- 技能树UI显示（T键打开）

待实现：
- 快捷栏拖拽配置
- 冷却旋转遮罩
```

### 4.4 物品系统

```
ItemBase (Resource)
├── 属性: name, type, icon, duration, value
├── 方法: apply(hero) → void
├── 方法: remove(hero) → void  (仅限时效物品)

物品列表（12种）：
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

**物品掉落机制（2026-05-11更新）**：
```
基础掉落率: 10%
Fortuna加成: 乘法加成 (LV1: 11.5%, LV10: 16%)

掉落判定流程:
1. 击败敌人 → 计算掉落概率（基础10% × Fortuna加成）
2. randf() < 概率 → 决定是否掉落
3. 根据稀有度权重选择物品类型:
   - Common(40%): 生命药水、法力药水
   - Uncommon(30%): 恢复药水、加速
   - Unique(15%): 经验书、魔法护盾
   - Rare(10%): 物理护盾、四倍伤害、免费施法
   - Exceptional(5%): 属性点、技能点、无敌
4. 在选定稀有度中随机选择具体物品
5. 生成掉落物（图标大小1.5倍，碰撞体积半径24）

拾取方式:
- 触碰自动拾取
- Telekinesis被动: 鼠标悬停自动拾取（带进度条显示，1.0-0.55秒）
```

### 4.5 物品拾取与使用

```
已实现：
- 怪物死亡时在位置生成 Area2D 物品
- 英雄靠近（范围内）自动拾取
- Telekinesis被动悬停拾取（带进度条）
- 时效物品在 HUD 上显示 Buff 图标
- 时效结束时自动移除效果

待实现：
- 拾取音效
```

**产出物**：
- [x] 21 个法术独立脚本
- [x] 12 种物品脚本
- [x] 物品掉落 + 自动拾取 + Telekinesis悬停拾取
- [x] Buff/Debuff 图标显示系统
- [x] 冷却显示系统（旋转遮罩）

---

## 5. 第三阶段：怪物体系与 AI

> **目标**：8 种怪物各有特色 AI
> **预计时间**：5-7 天
> **难度**：⭐⭐⭐
> **状态**：✅ 已完成

### 5.1 怪物类型（全部已实现）

| 怪物 | 行为 | 特殊 | 难度 | 状态 |
|------|------|------|------|------|
| **Spider** (蜘蛛) | 近战追踪，速度中等 | 无 | ⭐ | ✅ 已实现 |
| **Zombie** (僵尸) | 近战追踪，速度慢 | 低血量，低伤害，最弱怪 | ⭐ | ✅ 已实现 |
| **Bear** (熊) | 近战追踪，速度慢 | 高血量，高伤害 | ⭐⭐ | ✅ 已实现 |
| **Mummy/Archer** (弓手) | 远程射击，保持距离 | 远程攻击，逃跑转身 | ⭐⭐ | ✅ 已实现 |
| **Demon** (恶魔) | 快速追踪 | 追击时速度+40% | ⭐⭐⭐ | ✅ 已实现 |
| **Reaper** (死神) | 远程火焰攻击 | 发射3个追踪火焰 | ⭐⭐⭐ | ✅ 已实现 |
| **Troll** (巨魔) | 近战追踪 | 高血量，缓慢但坚韧 | ⭐⭐ | ✅ 已实现 |
| **Diablo/Boss** (首领) | 召唤怪物 | 不直接攻击，每5秒召唤4只怪 | ⭐⭐⭐⭐ | ✅ 已实现 |

### 5.2 怪物继承树（2026-05-13 更新）

```
MonsterBase (monster_base.gd)
├── monster_melee.gd (近战行为：追击→攻击)
│     ├── monster_spider.gd
│     ├── monster_bear.gd
│     ├── monster_demon.gd (追击加速+40%)
│     └── monster_troll.gd
└── monster_ranged.gd (远程行为：保持距离、射箭、逃跑转身)
      └── monster_mummy.gd (Archer，使用Mummy贴图)
      
特殊：
  ├── monster_reaper.gd (直接继承monster_base，远程火焰攻击)
  └── monster_diablo.gd (直接继承monster_base，Boss，召唤行为)
```

### 5.3 怪物配置（数据驱动，来自 monster_database.gd）

| 怪物 | 类型 | 血量/级 | 基础速度 | 基础伤害 | 检测范围 | 攻击范围 | min_dist | 攻击间隔 | 特殊行为 |
|------|------|---------|---------|---------|----------|----------|----------|----------|----------|
| Troll | 近战 | 7 | 60 | 5 | **400** | **40** | 40 | 2.0s | 弱近战 |
| Spider | 近战 | 10 | 60 | 6 | **400** | **40** | 40 | 2.0s | 坚韧昆虫 |
| Demon | 近战 | 8 | 60 | 8 | **400** | **40** | 40 | 2.0s | 追击时速度+40% |
| Bear | 近战 | 9 | 65 | 10 | **400** | **40** | 40 | 2.0s | 强近战 |
| Mummy | 远程 | 4 | 65 | 4 | **500** | 150-300 | 150 | 2.0s | 射箭保持距离 |
| Reaper | 远程 | 10 | 60 | 4 | **500** | 150-340 | 150 | 5.0s | 3火焰魔法攻击 |
| Diablo | 远程 | 25 | 55 | 0 | **500** | 150-380 | 150 | 15.0s | 召唤其他怪物 |

**注意**：
- 近战攻击范围 = min_distance = 40px（贴身才攻击）
- 远程攻击范围 = 150-380px（保持距离射击）
- 检测范围：近战统一400px，远程统一500px
- 所有数值随等级和难度动态缩放（详见 monster_database.gd）

### 5.4 怪物生成系统（2026-05-11 更新）

```gdscript
# 统一生成系统（Quest/Survival 均适用）
- 所有怪物从地图边缘生成（非玩家周围）
- 安全边界 spawn_margin=80px（Quest用100px），避免卡在墙里
- 随机选择四边（上/右/下/左）
- Survival: 定时生成（间隔1秒），最大15只，含Diablo特殊生成逻辑
- Quest: 按波次生成（4/6/9只一组），波次完成后停止
- 数据驱动：根据玩家等级和难度选择怪物类型
```

### 5.5 怪物游荡行为（2026-05-11 更新）

```gdscript
# 统一游荡系统（所有模式）
- wander_mode = true（默认启用）
- 生成时随机初始方向
- 碰到墙壁像光线反射一样反弹（X/Y轴分别取反）
- 反弹后添加 ±0.3 弧度随机偏移
- 游荡速度 = 正常移动速度（非50%减速）
- 发现玩家后切换为追击状态
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
- [x] 7 种怪物独立场景和脚本
- [x] 怪物远程攻击投射物（Arrow, Flame）
- [x] 特殊能力（Demon追击加速、Reaper火焰、Diablo召唤）
- [x] 波次生成系统（Quest模式10关）
- [x] 难度 scaling 公式（monster_database.gd）
- [x] 统一边缘生成系统
- [x] 统一墙壁反弹游荡系统

---

## 6. 第四阶段：地图与关卡

> **目标**：8+ 张可游玩的关卡地图
> **预计时间**：7-10 天
> **难度**：⭐⭐⭐
> **状态**：🔧 待实现

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
> **状态**：部分完成

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

**文件**：`Scenes/Menus/MainMenu.tscn`（待创建）

### 7.2 英雄面板（已实现）

```
按 T 键打开：
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
│  技能树 (8列×4行):                  │
│    [技能图标网格，带连线]             │
│                                     │
└─────────────────────────────────────┘
```

**文件**：`Scenes/HeroPanel.tscn` ✅ 已实现

### 7.3 游戏内 HUD（已实现 - 2026-05-13 重构）

```
┌──────────────────────────────────────┐
│                                      │
│         (游戏画面)                     │
│                                      │
│                                      │
├──────────────────────────────────────┤
│ [Buff/Debuff图标区域]                  │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ Lv.10 ████████████░░ HP 280/280 │ │
│ │       ██████░░░░░░░░ MP 150/150 │ │
│ │ [技能栏: 图标1 图标2 ... 图标8]    │ │
│ ├──────────────────────────────────┤ │
│ │████████████████████████████████░░│ │
│ │          LEVEL 10                │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘

布局说明：
- 左侧信息区：等级 + HP/MP 条（垂直排列）
- 右侧技能栏：8个技能图标（34×34px，间距2px）
- 底部通栏经验条：全宽，居中显示 "LEVEL X"
- 整体底栏高度：86px（比旧版更矮）
```

**文件**：`Scenes/HUD.tscn` ✅ 已实现

### 7.4 其他界面

| 界面 | 入口 | 功能 | 状态 |
|------|------|------|------|
| Options | 主菜单 / 游戏中暂停 | 音量、按键设置、画面 | 🔧 待实现 |
| High Scores | 主菜单 | 本地 + 在线排行 | 🔧 待实现 |
| Credits | 主菜单 | 制作人员名单 | 🔧 待实现 |
| Pause Menu | 游戏中按 Esc | 继续 / 保存 / 读取 / 返回主菜单 / 退出 | ✅ 已实现 |
| Game Over | 英雄死亡 | 显示统计 / 重试 / 返回主菜单 | ✅ 已实现 |
| Level Complete | 通关 | 统计 / 继续下一关 | ✅ 已实现 |
| Victory Screen | 全10关通关 | 祝贺 / 返回主菜单 | ✅ 已实现 |

### 7.5 按键设置（当前实现）

| 功能 | 默认键 |
|------|--------|
| 移动 | WASD |
| 主法术 (Magic Missile) | 鼠标左键 |
| 副法术 (Fireball) | 鼠标右键 |
| 法术 (Freezing Spear) | Z |
| 法术 (Prayer) | X |
| 法术 (Heal) | C |
| 法术 (Teleport) | 2 |
| 法术 (Mist Fog) | 3 |
| 法术 (Wrath of God) | 4 |
| 法术 (Telekinesis) | Q |
| 法术 (Sacrifice) | R |
| 法术 (Holy Light) | E |
| 法术 (Fire Walk) | U |
| 法术 (Meteor) | F |
| 法术 (Armageddon) | G |
| 法术 (Poison Cloud) | H |
| 法术 (Fortuna) | V |
| 法术 (Dark Ritual) | B |
| 法术 (Nova) | N |
| 法术 (Ball Lightning) | I |
| 法术 (Chain Lightning) | O |
| 打开英雄面板 | T |
| 显示怪物血量 | Alt（按住） |
| 暂停 | Esc |
| DevMode（测试模式） | F2 |

**产出物**：
- [x] 英雄面板（属性加点/技能树）
- [x] 游戏内HUD（血/蓝/经验条 + Buff图标 + 伤害红晕shader）
- [ ] 主菜单（新游戏/读档/设置/制作组）
- [x] 暂停菜单
- [x] 游戏结束界面
- [x] 关卡完成界面
- [x] 通关画面
- [ ] 选项设置
- [ ] 高分榜
- [ ] 按键配置（可自定义）

---

## 8. 第六阶段：游戏模式与进度

> **目标**：完整的游戏循环
> **预计时间**：4-6 天
> **难度**：⭐⭐⭐
> **状态**：部分完成

### 8.1 游戏模式

```
剧情模式 (Quest)：
  10 关顺序推进 ✅ 已实现
  每关任务：清怪 / 生存
  通关后解锁下一关

生存模式 (Survival)：
  单张地图，无限波次 ✅ 已实现
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

### 8.4 经验与升级曲线（2026-05-11 更新）

```
经验公式（已简化）：
  升级所需经验 = level × 200
  
  每升一级：
  - 5 个属性点
  - 1 个技能点
  - 自动回满血和蓝

属性加点效果：
  Strength (+1):  +10 生命上限
  Dexterity (+1): +0.5 移动速度，+0.4% 闪避
  Stamina (+1):   +0.1/秒 生命恢复，+0.35 移速
  Intelligence (+1): +6 法力上限，+0.06/秒 法力恢复
  Wisdom (+1):   +2 法力上限，+0.18/秒 法力恢复
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
- [x] Quest模式10关线性推进（已实现）
- [x] 生存模式无限生成（已实现）
- [x] 存档/读档系统（F5/F10，JSON格式，已实现）
- [ ] 多 Profile 支持
- [ ] 在线/本地高分榜
- [x] 经验与升级系统（简化公式已实现）
- [x] 3 种难度配置（Normal/Nightmare/Hardcore，已实现）
- [ ] Quest模式关卡解锁持久化
- [ ] Quest模式Boss战特殊设计
- [ ] Quest模式通关奖励

---

## 9. 第七阶段：打磨与发布

> **目标**：商业级品质
> **预计时间**：7-14 天
> **难度**：⭐⭐⭐
> **状态**：🔧 待实现

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
  [ ] 所有 21 种法术施放正常
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
  DEXTERITY_ON_SPEED:        每点 +0.5 移动速度
  DEXTERITY_ON_CHANCE_TO_BE_HIT: 增加闪避（每点-0.4%）

STAMINA (耐力):
  STAMINA_ON_HEALTH_REGENERATION: 增加 HP 恢复速度（每点+0.1/秒）
  STAMINA_ON_SPEED:                 少量移速加成（每点+0.35）

INTELLIGENCE (智力):
  INTELLIGENCE_ON_MANA:             每点 +6 MP
  INTELLIGENCE_ON_MANA_REGENERATION: 增加 MP 恢复（每点+0.06/秒）

WISDOM (智慧):
  WISDOM_ON_MANA:             少量 MP 加成（每点+2）
  WISDOM_ON_MANA_REGENERATION: MP 恢复加成（每点+0.18/秒）
```

### 10.2 法术参考数值（估算）

```
法术           | 法力  | 冷却  | 基础伤害
───────────────|───────|───────|────────
火球术         | 10    | 0.3s  | 15-25
冰冻矛         | 15    | 0.5s  | 20-30
治疗术         | 15    | 1.0s  | +30 HP
陨石术         | 35    | 1.5s  | 50-80
新星术         | 25    | 0.8s  | 20-35
毒云术         | 20    | 1.0s  | 10/秒 (持续)
传送术         | 15    | 2.0s  | —
神之愤怒       | 50    | 3.0s  | 100-150
世界末日       | 60    | 5.0s  | 150-200
球状闪电       | 25    | 2.0s  | 30-50
连锁闪电       | 30    | 3.0s  | 40-60
```

### 10.3 怪物参考数值

```
怪物   | HP   | 伤害 | 速度 | 经验
───────|──────|──────|──────|─────
蜘蛛   | 20   | 5    | 40   | 15
僵尸   | 15   | 3    | 35   | 10
熊     | 80   | 12   | 50   | 30
弓手   | 40   | 8    | 30   | 20
恶魔   | 50   | 10   | 45   | 35
死神   | 25   | 6    | 60   | 25
巨魔   | 60   | 8    | 35   | 20
Boss   | 300  | 20   | 40   | 200
```

### 10.4 物品参考数值

```
物品            | 持续时间 | 效果值
────────────────|─────────|───────
Health Potion   | 瞬间    | +50 HP
Mana Potion     | 瞬间    | +50 MP
Rejuvenation    | 瞬间    | +50 HP + 50 MP
Quad Damage     | 30s     | 伤害 ×4
Physic Shield   | 30s     | 物理伤害-50%
Magic Shield    | 30s     | 魔法伤害-50%
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

## 里程碑时间线（2026-05-11 更新）

```
Phase 0: Demo 可用                    ✅ 已完成
Phase 1: 核心战斗系统                  ✅ 已完成
  ├── ✅ WASD移动 + 鼠标瞄准
  ├── ✅ 碰撞体系
  ├── ✅ 受伤反馈
  ├── ✅ 死亡与重生
  └── ✅ 无敌帧机制
Phase 2: 法术与物品系统                ✅ 已完成
  ├── ✅ 21个技能独立重构
  ├── ✅ 12种物品
  ├── ✅ 掉落系统
  ├── ✅ Buff/Debuff系统
  └── 🔧 音效系统（待实现）
Phase 3: 怪物体系与 AI                ✅ 已完成
  ├── ✅ 8种怪物实现
  ├── ✅ 独立脚本架构
  ├── ✅ 特殊AI行为
  ├── ✅ 波次系统（Quest模式10关）
  ├── ✅ 四种生成模式（单个/整排/编组/全边界）
  └── ✅ 统一边缘生成+墙壁反弹游荡
Phase 4: 地图与关卡                   🔧 待实现
Phase 5: UI 与菜单系统                ✅ 大部分完成
  ├── ✅ 主菜单（含New Game/Controls Guide/Quit）
  ├── ✅ 英雄面板（属性加点/技能树）
  ├── ✅ 游戏内HUD（血/蓝/经验条 + Buff图标 + 伤害红晕shader）
  ├── ✅ 暂停菜单
  ├── ✅ 游戏结束界面
  ├── ✅ 关卡完成界面
  ├── ✅ 通关画面
  ├── ✅ Controls Guide 操作指南
  ├── 🔧 选项设置
  ├── 🔧 高分榜
  └── 🔧 按键配置（可自定义）
Phase 6: 游戏模式与进度               🔧 部分完成
  ├── ✅ Quest模式10关
  ├── ✅ 生存模式无限波次
  ├── ✅ 存档/读档系统
  ├── 🔧 关卡解锁持久化
  └── 🔧 Quest模式通关奖励
Phase 7: 打磨与发布                   🔧 待实现
  ├── ✅ 游戏导出配置准备 + 已成功导出加密版单 exe
  ├── ✅ 下载导出模板完成导出
  └── 🔧 音效系统

总计：约 38-59 天（1.5-2 个月全职开发）
```

---

> 本文档会随项目进展持续更新。
> 最后更新：2026-05-16