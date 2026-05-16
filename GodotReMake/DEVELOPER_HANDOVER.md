# Evil Invasion (Godot 4.6 Remake) - 开发者交接文档

> **项目**: Evil Invasion (2006年Flash游戏重制版)
> **引擎**: Godot 4.6.2-stable
> **语言**: GDScript
> **作者**: [Previous Agent]
> **日期**: 2026-05-14
> **最后更新**: v12 Agent — hero.gd全面重构 + 统一施法调度 + 冷却缩减遗物修正 + 全项目性能优化
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
- **✅ 统一英雄出生点**：Survival和Quest模式英雄均出生在地图中心 (768, 768)（地图 1536×1536）
- **✅ 存档系统**：F5保存/F10读取，JSON格式，保存英雄状态、属性、技能、位置
- **✅ 受击恢复系统**：被攻击后不能施法+减速20%，力量减少恢复时间
- **✅ 四种怪物生成模式**：单个(1~3秒)/整排(18~22秒)/编组(8~12秒)/全边界(38~42秒)
- **✅ 怪物死亡动画**：16帧 Death spritesheet 动画，播完自动销毁（原为0.25秒渐隐）
- **✅ 英雄/怪物行走动画**：全部 spritesheet 循环播放
- **✅ 英雄/怪物攻击动画**：Attack1 动画，含远程怪物
- **✅ 比例修正**：地图 1024×1024，zoom=1.0，scale 补偿移除
- **✅ 原版贴图**：从 Data.pak 合成替换占位方块

### 游戏操作

| 按键 | 功能 |
|------|------|
| WASD | 移动 |
| 鼠标左键 | 快捷槽位LMB（可自定义技能） |
| 鼠标右键 | 快捷槽位RMB（可自定义技能） |
| Shift | 快捷槽位Shift（可自定义技能） |
| Space | 快捷槽位Space（可自定义技能） |
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
| F5 | 保存游戏 |
| F10 | 读取存档 |
| ESC | 暂停菜单 |
| 左Alt | 切换怪物信息显示 |

---

## 2. 项目结构

```
GodotReMake/
├── project.godot              # 项目配置和输入映射
├── Scenes/
│   ├── Main.tscn              # 主场景（游戏入口）
│   ├── Hero.tscn              # 玩家英雄场景
│   ├── Troll.tscn             # Troll场景
│   ├── Spider.tscn            # 蜘蛛场景
│   ├── Bear.tscn              # 熊场景
│   ├── Mummy.tscn             # 木乃伊/弓手场景
│   ├── Reaper.tscn            # 死神场景
│   ├── Demon.tscn             # 恶魔场景
│   ├── Diablo.tscn            # 特殊怪物场景
│   ├── MonsterArrow.tscn      # 怪物弓箭投射物
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
│   ├── MeteorSingle.tscn      # 单颗陨石子场景
│   ├── Armageddon.tscn        # Armageddon 独立场景
│   ├── ArmageddonZone.tscn    # Armageddon 区域子场景
│   ├── PoisonCloud.tscn       # Poison Cloud 独立场景
│   ├── Nova.tscn              # Nova 独立场景
│   ├── NovaProj.tscn          # Nova 投射物子场景
│   ├── DarkRitual.tscn        # Dark Ritual 独立场景
│   ├── BallLightning.tscn     # Ball Lightning 独立场景
│   ├── ChainLightningProj.tscn # Chain Lightning 投射物场景
│   ├── Explosion.tscn         # 爆炸特效
│   ├── PickupItem.tscn        # 拾取物品
│   ├── HUD.tscn               # 游戏内HUD（瘦底栏+通栏经验条+伤害红晕）
│   ├── HeroPanel.tscn         # 英雄面板（技能树 + 属性分配）
│   ├── SkillButton.tscn       # 技能按钮UI
│   ├── BuffIcon.tscn          # Buff图标
│   ├── GameModeSelect.tscn    # 游戏模式选择
│   ├── LevelSelect.tscn       # 关卡选择器（Quest模式）
│   ├── QuestMain.tscn         # Quest模式主场景
│   ├── PauseMenu.tscn         # 暂停菜单（ESC打开）
│   ├── GameOverScreen.tscn    # 死亡画面覆盖层
│   ├── LevelCompleteScreen.tscn # 关卡完成画面
│   └── VictoryScreen.tscn     # 全通通关画面
├── Scripts/
│   ├── global.gd              # 全局单例（自动加载）
│   ├── object_pool.gd         # 对象池单例（自动加载）v7新增
│   ├── hero.gd                # 英雄逻辑（移动、技能施放）
│   ├── monster_spawner.gd     # 怪物生成器（Survival模式）
│   ├── level_select.gd        # 关卡选择器逻辑
│   ├── save_manager.gd        # 存档管理器
│   ├── projectile.gd          # 通用投射物逻辑（对象池化）
│   ├── pause_menu.gd          # 暂停菜单逻辑
│   ├── game_over_screen.gd    # 死亡画面逻辑
│   ├── level_complete_screen.gd # 关卡完成画面逻辑
│   ├── victory_screen.gd      # 通关画面逻辑
│   ├── cooldown_overlay.gd    # 技能冷却扇形遮罩控件
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
│   │   ├── meteor_single.gd
│   │   ├── armageddon.gd
│   │   ├── armageddon_zone.gd
│   │   ├── poison_cloud.gd
│   │   ├── fortuna.gd
│   │   ├── dark_ritual.gd
│   │   ├── nova.gd
│   │   ├── nova_proj.gd
│   │   ├── ball_lightning.gd
│   │   ├── chain_lightning.gd
│   │   ├── chain_lightning_proj.gd
│   │   ├── explosion.gd
│   │   ├── projectile.gd
│   │   └── skill_button.gd
│   ├── Monsters/              # 怪物脚本目录（7种）
│   │   ├── monster_base.gd
│   │   ├── monster_melee.gd
│   │   ├── monster_ranged.gd
│   │   ├── monster_troll.gd
│   │   ├── monster_spider.gd
│   │   ├── monster_bear.gd
│   │   ├── monster_mummy.gd (Archer)
│   │   ├── monster_reaper.gd
│   │   ├── monster_demon.gd
│   │   ├── monster_diablo.gd (特殊怪物)
│   │   ├── monster_arrow.gd
│   │   └── monster_database.gd
│   ├── explosion.gd           # 爆炸特效逻辑
│   ├── pickup_item.gd         # 拾取物品逻辑
│   ├── loot_manager.gd        # 掉落管理器（自动加载）
│   ├── hud.gd                 # HUD更新逻辑（含伤害红晕shader）
│   ├── hero_panel.gd          # 英雄面板主逻辑
│   ├── skill_button.gd        # 技能按钮组件逻辑
│   ├── buff_icon.gd           # Buff图标逻辑
│   ├── game_mode_select.gd    # 游戏模式选择逻辑
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
- [x] **FireWalk 重构**：独立场景 + toggle类技能（按U开关）+ 移动产生火焰轨迹 + U键绑定
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
- [x] 死亡动画（16帧 Death spritesheet，~1.28s，播完自动 queue_free）
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
| Diablo | 远程 | 25/级 | 55 | 0 | **500** | 150-380 | 150 | 15.0s | 召唤其他怪物（非Boss，是特殊怪物） |

**注意**：
- 近战怪物攻击范围 = min_distance = 40px（贴身才攻击）
- 远程怪物攻击范围 = 150-380px（保持距离射击）
- 检测范围：近战统一400px，远程统一500px
- 所有数值随等级和难度动态缩放

**怪物脚本架构：**
```
monster_base.gd (核心功能：移动、受击、死亡、元素光环)
  ├── monster_melee.gd (近战行为：追击→攻击)
  │     ├── monster_troll.gd
  │     ├── monster_spider.gd
  │     ├── monster_bear.gd
  │     └── monster_demon.gd (追击加速+40%)
  └── monster_ranged.gd (远程行为：保持距离、射箭、逃跑转身)
        └── monster_mummy.gd (Archer，使用Mummy贴图)

特殊（直接继承monster_base）：
  ├── monster_reaper.gd (远程火焰攻击)
  └── monster_diablo.gd (特殊怪物，召唤行为)
```

### 3.7 怪物生成 (monster_spawner.gd / quest_monster_spawner.gd)
- [x] **统一边缘生成**：所有模式（Quest/Survival）怪物均从地图边缘生成
- [x] 安全边界（spawn_margin=80px），避免卡在墙里
- [x] 随机选择四边（上/右/下/左）生成
- [x] Survival：定时生成（间隔1秒），最大15只，含Diablo特殊生成逻辑
- [x] Quest：按波次生成（4/6/9只一组），所有波次完成后停止
- [x] 数据驱动：根据玩家等级和难度动态选择怪物类型和数值

### 3.8 掉落系统 (loot_manager.gd)
- [x] 5种稀有度（Common, Uncommon, Unique, Rare, Exceptional）
- [x] 12种物品类型（药水、卷轴、护盾、增益等）
- [x] 基础掉落率10%（受Fortuna技能影响）
- [x] 物品自动消失（10秒 lifetime）
- [x] 掉落物图标原生大小 34×34，碰撞体积半径 18

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

- [x] 生命值条（底部左侧）
- [x] 法力值条（底部左侧）
- [x] 通栏经验值条（底部全宽，居中显示 "LEVEL X"）
- [x] 等级显示
- [x] **Buff/Debuff 图标显示**（底部栏上方居中，带扇形冷却效果）
- [x] **技能栏冷却显示**（灰色扇形遮罩覆盖技能图标）
- [x] **受击红晕（Damage Vignette）**（血量<50%时径向渐变红色边缘）
- [x] **怪物信息切换（Alt键）**（显示/隐藏怪物血条和伤害数字）
- [x] **瘦底栏设计**：整体高度86px，左侧信息区+右侧技能栏+底部通栏经验条
- [x] **快捷槽位系统（4槽位 2×2网格）**：LMB/RMB/Shift/Space，悬浮分配快捷键，存档持久化

### 3.12 摄像机 (camera.gd)
- [x] 平滑跟随玩家
- [x] zoom = 1.0（还原原版视野比例）

### 3.11 对象池系统（v7 新增）

- [x] **ObjectPool Autoload**：`Scripts/object_pool.gd`，管理高频对象的复用
- [x] **池化对象**：Projectile(20)/MagicMissile(15)/NovaProj(10)/ChainLightningProj(10)/MonsterArrow(15)/ArmageddonZone(5)
- [x] **16个脚本已重构**使用 `ObjectPool.get_object()` / `ObjectPool.return_to_pool()`
- [x] **短命特效不池化**：Explosion/Armageddon闪光/MeteorSingle寿命<1s，恢复 instantiate
- [x] **`reset_for_pool()` 协议**：池化对象必须实现此方法重置状态
- [x] **安全回退**：场景不在池中时自动 `queue_free()`

### 3.12 怪物刷怪修复（v7 新增）

- [x] **移除 max_monsters=15 硬上限**：所有4种生成模式无上限独立运转
- [x] **Diablo 追踪修复**：从名字字符串匹配改为数组精确追踪
- [x] **计数器保护**：active_monsters 不会低于0

### 3.13 Data.pak 全量提取（v7 新增）

- [x] **92个文件全部解密**：使用 XOR 0xA5 解密
- [x] **提取工具**：`e:\EvilInvasion\extract_all.py`
- [x] **提取位置**：`e:\EvilInvasion\extracted_all/`
- [x] **关键配置**：MonsterBalance, SpellBalance, HeroBalance, ItemBalance, MapDesc, SpellDesc
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
| 等级上限 | 每关经验上限（见下方） | 无上限 |
| 通关条件 | 达到经验上限 + 清除所有怪物 | 无（直到死亡） |
| 怪物生成 | 地图边缘，持续生成 | 地图边缘，持续生成 |
| 怪物行为 | 随机游荡 + 发现玩家后追击 | 随机游荡 + 发现玩家后追击 |
| 关卡数 | 10关线性推进 | 1张地图 |

### 5.3 关卡配置（10关）

| 关卡 | 名称 | 经验上限 | 允许怪物 |
|------|------|---------|---------|
| 1 | Ancient Way | 2000 | troll, mummy |
| 2 | Burned Land | 5200 | troll, mummy, spider |
| 3 | Desert Battle | 8400 | troll, mummy, spider |
| 4 | Forgotten Dunes | 11600 | troll, mummy, spider, bear |
| 5 | Dark Swamp | 14800 | troll, mummy, spider, bear, demon |
| 6 | Skull Coast | 18000 | troll, mummy, spider, bear, demon |
| 7 | Snowy Pass | 21200 | troll, mummy, spider, bear, demon, reaper |
| 8 | Hell Eye | 24400 | troll, mummy, spider, bear, demon, reaper, diablo |
| 9 | Inferno | 27600 | troll, mummy, spider, bear, demon, reaper, diablo |
| 10 | Diablo's Lair | 30800 | troll, mummy, spider, bear, demon, reaper, diablo |

**经验上限计算**：每关4级，每级需要 `level * 200` 经验，累计求和。
- 第1关：200+400+600+800 = 2000
- 第2关：1000+1200+1400+1600 = 5200
- ...

**怪物解锁设计**：
- 第1关：troll, mummy（基础怪物）
- 第2关：+ spider（新增）
- 第3关：同第2关
- 第4关：+ bear（新增）
- 第5关：+ demon（新增）
- 第6关：同第5关
- 第7关：+ reaper（新增）
- 第8关：+ diablo（遇到所有怪物）
- 第9-10关：同第8关（全部怪物）

### 5.4 核心脚本

1. **`Scripts/Quest/quest_level_manager.gd`** — 关卡管理器
   - 管理10关的配置和进度
   - **经验上限系统**：检测本关获得的总经验值，达到上限后停止经验获取和怪物生成
   - **通关条件**：达到经验上限 + 清除地图上所有存活怪物
   - 通关后保存下一关进度，返回关卡选择器
   - 自动存档：通关时自动保存到存档槽位2

2. **`Scripts/Quest/quest_monster_spawner.gd`** — 怪物生成器
   - 从地图边缘持续生成怪物（安全边界80px）
   - 达到经验上限时停止生成（`stop_spawning()`）
   - 使用 `allowed_monsters` 限制每关出现的怪物种类
   - 无限生成（直到被手动停止）

3. **`Scripts/Quest/quest_hud_manager.gd`** — Quest专用HUD
   - 显示当前关卡名称和编号
   - 显示已击杀怪物数量
   - 显示等级上限警告
   - 显示关卡完成/全部完成提示

4. **`Scripts/level_select.gd`** — 关卡选择器
   - 显示10个关卡按钮（5列×2行）
   - 根据 `Global.quest_max_unlocked_level` 显示解锁状态
   - 已解锁：可点击，正常颜色
   - 已完成：显示"[已完成]"
   - 当前：显示"[当前]"
   - 未解锁：灰色，显示"[锁定]"
   - 点击关卡进入 QuestMain 场景

5. **`Scripts/Monsters/monster_base.gd`** — 怪物基类
   - `wander_mode` 变量控制游荡行为
   - 墙壁反弹逻辑
   - `set_experience_reward(0)`：达到经验上限时临时将怪物经验设为0

### 5.5 场景文件

- **`Scenes/QuestMain.tscn`** — Quest模式主场景
  - 地图大小：1024×1024
  - 玩家出生点：地图中心 **(512, 512)**
  - 包含 QuestLevelManager、QuestMonsterSpawner、QuestHUDManager

- **`Scenes/LevelSelect.tscn`** — 关卡选择器场景
  - 10个关卡按钮（动态创建）
  - Back to Menu 按钮
  - 显示关卡解锁状态

- **`Scenes/Main.tscn`** — Survival模式主场景
  - 地图大小：1024×1024
  - 玩家出生点：地图中心 **(512, 512)**
  - 包含 MonsterSpawner、HUD

### 5.6 存档系统（Quest模式）

**自动存档时机**：只在通关时存档（不再频繁存档）

**保存内容**：
- `quest_progress.current_level`：下一关索引
- `quest_progress.monsters_killed`：0（从开头开始）
- `quest_progress.monsters_spawned`：0
- `quest_progress.level_start_level`：当前玩家等级（保留）
- `quest_progress.has_progress`：true
- `quest_max_unlocked_level`：最大解锁关卡（解锁下一关）
- 玩家属性、技能等级（通过 Global 保存）

**Resume Game 行为**：
- 从关卡选择器开始
- 已解锁的关卡可点击
- 选择关卡后从该关开头开始
- 保留玩家等级、属性点、技能等级

### 5.7 已知问题

1. **地图背景单一**：10关使用相同的地面贴图
2. **通关奖励未实现**：通关后没有奖励结算画面
3. **关卡选择器UI简陋**：需要更好的视觉效果

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
| Fire Walk | U | fire | toggle | 移动产生火焰轨迹，持续DOT |
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
1. **怪物攻击冷却**：使用 `await` 可能导致协程问题
2. **没有音效**：所有技能目前没有音效（用户打算最后做）
3. **地图系统**：原版有多张地图，目前只有一张测试地图（美术资源，建议后期做）
4. **Quest模式关卡解锁未持久化**：Quest进度需要Resume Game功能支持
5. **Quest模式通关奖励未实现**：通关后没有奖励结算画面
6. **怪物贴图缺失**：所有怪物使用占位方块，需从原版 Data.pak 提取 DDS 纹理
7. **英雄贴图缺失**：英雄使用蓝色方块，需替换为原版精灵
8. **选项设置缺失**：无音量/按键自定义/画面设置

### 6.2 已解决的问题（2026-05-15更新）
1. **✅ 高等级技能测试**：所有21个技能高等级形态已测试通过
2. **✅ 存档系统**：已实现（F5保存/F10读取，JSON格式）
3. **✅ 技能数值平衡**：已参考Excel文件完成数值调整
4. **✅ Quest模式经验上限系统**：改为基于本关总经验值，达到上限后停止经验获取和怪物生成
5. **✅ Quest模式关卡选择器**：新增 LevelSelect.tscn，显示10关解锁状态
6. **✅ Quest模式存档持久化**：通关时自动保存，Resume时从关卡选择器开始
7. **✅ Quest模式怪物种类限制**：每关使用 `allowed_monsters` 限制出现的怪物种类
8. **✅ 暂停菜单（PauseMenu）**：ESC打开，含Resume/Save/Load/Return/Quit
9. **✅ 死亡画面（GameOverScreen）**：显示统计+Retry/Return
10. **✅ 关卡完成画面（LevelCompleteScreen）**：统计+Continue
11. **✅ 通关画面（VictoryScreen）**：全10关通关祝贺
12. **✅ 技能栏冷却显示**：灰色扇形遮罩
13. **✅ 怪物信息切换（Alt键）**：血条+伤害数字显示/隐藏
14. **✅ 受击红晕（Damage Vignette）**：血量<50%径向渐变红色边缘
15. **✅ HUD重构**：瘦底栏+通栏经验条+居中LEVEL显示
16. **✅ Survival模式经验追踪**：累积经验值显示在死亡统计中
17. **✅ 快捷槽位系统**：4槽位 2×2网格布局，LMB/RMB点击分配 + Shift/Space悬浮分配，存档持久化
18. **✅ 主菜单（MainMenu）**：含New Game/Controls Guide/Quit，Controls Guide可浏览操作指南
19. **✅ Controls Guide操作指南**：主菜单和暂停菜单均可打开，浏览快捷键说明
20. **✅ Firewalk Toggle重写**：从普通技能改为toggle类技能（按U开关），移动产生火焰DOT
21. **✅ 爆炸伤害检测统一**：所有范围技能从"怪物原点距离"改为"物理碰撞体重叠检测"
22. **✅ Teleport 输入修复**：在 `_process()` 中添加 `spell_teleport` 输入检测（v12从 _unhandled_input 移至 _process）
23. **✅ 暂停时设置Quickslot**：skill_bar_container设为PROCESS_MODE_ALWAYS
24. **✅ 技能tooltip数据修正**：所有技能调用实际静态方法，firewalk显示无mana cost+toggle描述
25. **✅ Meteor/Armageddon平衡**：陨石间隔0.2s→0.4s，每批15→12，贴图scale 0.8→0.5
26. **✅ Autocast间隔优化**：0.15s→0.1s
27. **✅ 游戏导出配置准备**：export_presets.cfg配置加密参数（encrypt_pck=true, encrypt_directory=false, script_export_mode=2, embed_pck=true），已成功导出加密版单exe

### 6.3 技术债务
1. **projectile.gd**：旧版通用投射物逻辑，逐步弃用
2. **Monster.tscn**：旧版怪物场景，逐步被独立怪物场景替代

---

## 7. 开发路线图

### 已完成 ✅
- 核心战斗系统
- 21个技能独立重构
- 属性分配系统
- 7种怪物实现
- 掉落系统
- 开发模式
- 经验值公式简化
- Quest模式基础系统 - 10关线性推进、波次生成、等级上限、边缘生成、游荡AI
- UI/UX系统 - 暂停菜单、死亡画面、关卡完成画面、通关画面、技能冷却显示、Alt键切换、受击红晕
- HUD重构 - 瘦底栏+通栏经验条+居中LEVEL显示
- Survival模式经验追踪 - 累积经验值死亡统计

### 待完成 🔧
1. **音效系统** - 为所有技能和事件添加音效（最后做，纯音频资源）
2. **Quest模式通关奖励** - 通关后显示奖励结算画面（时间、击杀数）
3. **UI完善** - 系别头像、更好的技能提示框、关卡选择器美化（优先做英雄面板UI优化）
4. **地图系统** - 原版8张地图，目前只有一张测试地图（最后做，纯美术资源）
5. **主菜单** - 新游戏/读档/设置/制作组
6. **选项设置** - 音量/按键自定义/画面设置（优先级低）
7. **性能优化** - 对象池、内存管理

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
