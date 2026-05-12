# Evil Invasion (Godot 4.6 Remake) — 游戏系统设计文档

> **文档版本**: 1.1
> **引擎版本**: Godot 4.6.2-stable
> **语言**: GDScript
> **最后更新**: 2026-05-13

---

## 目录

1. [游戏模式系统](#1-游戏模式系统)
2. [难度系统](#2-难度系统)
3. [英雄属性系统](#3-英雄属性系统)
4. [技能系统](#4-技能系统)
5. [怪物系统](#5-怪物系统)
6. [怪物刷新方式系统](#6-怪物刷新方式系统)
7. [怪物光环系统](#7-怪物光环系统)
8. [掉落物系统](#8-掉落物系统)
9. [Buff/Debuff 系统](#9-buffdebuff-系统)
10. [存档系统](#10-存档系统)
11. [UI/UX 系统](#11-uiux-系统)

---

## 1. 游戏模式系统

### 1.1 模式类型

游戏有两种模式，由 `Global.gd` 中的枚举定义：

```gdscript
enum GameMode { QUEST, SURVIVAL }
```

### 1.2 Survival 模式

- **经验值**: 正常获得
- **等级上限**: 无限制
- **怪物成长**: 40 级后怪物每级额外 +10% 血量和 +10% 速度（无限成长）
- **生成方式**: 使用通用刷怪器 `MonsterSpawner`（边缘生成 + 游荡）
- **目标**: 无尽生存，尽可能活更久

### 1.3 Quest 模式

- **经验值**: 减半获得（`amount * 0.5`）
- **经验上限**: 每关有固定的经验上限，达到后不再获得经验，怪物停止生成
- **关卡数量**: 10 关
- **怪物生成**: 使用 `QuestMonsterSpawner`，从边缘持续生成，达到经验上限后停止
- **通关条件**: 达到经验上限 + 清除地图上所有存活怪物
- **目标**: 通关所有关卡

### 1.4 Quest 关卡配置

| 关卡 | 名称 | 经验上限 | 允许怪物 |
|:---:|:-----------:|:--------:|:----------|
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

**经验上限计算**: 每关4级，每级需要 `level * 200` 经验，累计求和。
- 第1关：200+400+600+800 = 2000
- 第2关：1000+1200+1400+1600 = 5200
- ...

**怪物解锁设计**: 逐渐引入新怪物，第8关开始遇到所有种类。

### 1.5 关卡选择器

- **场景**: `Scenes/LevelSelect.tscn`
- **脚本**: `Scripts/level_select.gd`
- **功能**:
  - 显示10个关卡按钮（5列×2行）
  - 根据 `Global.quest_max_unlocked_level` 显示解锁状态
  - 已解锁：可点击，正常颜色
  - 已完成：显示"[已完成]"
  - 当前：显示"[当前]"
  - 未解锁：灰色，显示"[锁定]"
  - 点击关卡进入 QuestMain 场景

### 1.6 存档系统（Quest模式）

**自动存档时机**: 只在通关时存档

**保存内容**:
- `quest_progress.current_level`: 下一关索引
- `quest_progress.monsters_killed`: 0（从开头开始）
- `quest_progress.monsters_spawned`: 0
- `quest_progress.level_start_level`: 当前玩家等级（保留）
- `quest_progress.has_progress`: true
- `quest_max_unlocked_level`: 最大解锁关卡（解锁下一关）
- 玩家属性、技能等级（通过 Global 保存）

**Resume Game 行为**:
- 从关卡选择器开始
- 已解锁的关卡可点击
- 选择关卡后从该关开头开始
- 保留玩家等级、属性点、技能等级

---

## 2. 难度系统

### 2.1 难度类型

```gdscript
enum Difficulty { NORMAL, NIGHTMARE, HARDCORE }
```

### 2.2 难度修正系数

| 难度 | 怪物血量倍率 | 怪物速度倍率 |
|:----|:----------:|:----------:|
| **Normal** | 0.6 | 0.6 |
| **Nightmare** | 0.8 | 0.8 |
| **Hardcore** | 1.0 | 1.0 |

### 2.3 难度影响范围

- 所有怪物的血量（`health_per_level * level * health_mult`）
- 所有怪物的速度（`(speed_base + speed_per_level * level) * speed_mult`）
- 伤害不受难度直接影响

---

## 3. 英雄属性系统

### 3.1 基础属性

英雄有五个基础属性，初始均为 10 点，上限 100 点：

| 属性 | 初始值 | 上限 | 每级获得 |
|:----|:-----:|:----:|:--------:|
| Strength（力量） | 10 | 100 | 5 属性点/级 |
| Dexterity（敏捷） | 10 | 100 | 同上 |
| Stamina（耐力） | 10 | 100 | 同上 |
| Intelligence（智力） | 10 | 100 | 同上 |
| Wisdom（智慧） | 10 | 100 | 同上 |

### 3.2 属性 → 派生属性公式

| 属性 | 影响 | 公式 |
|:----|:-----|:-----|
| **Strength** | 最大生命值 | `max_health = strength * 10` |
| **Strength** | 受击恢复时间 | `hit_recovery = max(0.1, 0.5 - strength * 0.004)` |
| **Dexterity** | 移动速度 | `speed += dexterity * 0.5` |
| **Dexterity** | 被命中几率 | `chance_to_be_hit = max(0.04, 1.0 - dexterity * 0.004)` |
| **Stamina** | 生命恢复速率 | `health_regen = stamina * 0.1 / 秒` |
| **Stamina** | 移动速度 | `speed += stamina * 0.35` |
| **Intelligence** | 最大法力值 | `max_mana += intelligence * 6` |
| **Intelligence** | 法力恢复速率 | `mana_regen += intelligence * 0.06 / 秒` |
| **Wisdom** | 最大法力值 | `max_mana += wisdom * 2` |
| **Wisdom** | 法力恢复速率 | `mana_regen += wisdom * 0.18 / 秒` |

### 3.3 生命值与法力值系统

- **初始生命值**: 100 (由 10 力量 × 10 计算)
- **初始法力值**: 50 (由 10 智力 × 6 + 10 智慧 × 2 = 60 + 20 = 80，代码中初始 50)
- **自动恢复**:
  - 生命恢复 = `stamina * 0.1` 点/秒（每点耐力恢复 0.1 HP/秒）
  - 法力恢复 = `intelligence * 0.06 + wisdom * 0.18` 点/秒
- **升级**: 自动回满血和蓝

### 3.4 经验值与升级系统

- **升级所需经验**: `level * 200`
- **每级获得**: 5 属性点 + 1 技能点
- **经验来源**: 击杀怪物（怪物经验值受难度影响）
- **Quest 模式**: 经验值减半

### 3.5 受击恢复系统 (Hit Recovery)

- **基础恢复时间**: 0.5 秒
- **公式**: `hit_recovery = max(0.1, 0.5 - strength * 0.004)`
- **效果**:
  - 受击恢复期间**不能施法**（所有技能按键无效）
  - 移动速度降低 20%（通过 `hit_slow` debuff 实现）
  - 每次受到攻击**刷新**恢复时间
- **力量影响**: 力量越高，恢复时间越短
  - 10 点力量: 0.46 秒
  - 50 点力量: 0.30 秒
  - 100 点力量: 0.10 秒（最低值）
- **实现文件**: `hero.gd` 中的 `_on_hero_took_damage()` 和 `_process()`

---

## 4. 技能系统

### 4.1 技能列表（21个技能）

| 技能名称 | 按键 | 类型 | 元素属性 | 说明 |
|:---------|:----:|:----:|:--------:|:-----|
| Magic Missile | 鼠标左键 | 投射物 | basic | 追踪弹，自动追击最近敌人 |
| Fireball | 鼠标右键 | 投射物 | fire | 火球，命中后爆炸 AOE |
| Freezing Spear | Z | 投射物 | water | 直线穿透，冰冻效果 |
| Prayer | X | 持续效果 | earth | 持续扣血回蓝 |
| Heal | C | 持续效果 | fire | 持续回血 |
| Teleport | 2 | 位移 | earth | 闪现到鼠标位置 |
| Mist Fog | 3 | 场地 | earth | 区域减速敌人 |
| Wrath of God | 4 | 全屏 AOE | earth | 全屏伤害 |
| Telekinesis | Q | 被动 | air | 隔空取物，鼠标悬停拾取 |
| Sacrifice | R | 秒杀 | air | 消耗生命直接秒杀怪物 |
| Holy Light | E | 射线 | air | 射线伤害 |
| Fire Walk | U | 场地 | fire | 火焰轨迹持续伤害 |
| Meteor | F | 延迟 AOE | fire | 延迟后陨石坠落 |
| Armageddon | G | 全屏随机 | fire | 全屏随机落石 |
| Poison Cloud | H | 场地 | water | 区域持续毒伤害 |
| Fortuna | V | 被动 | water | 增加掉落率 |
| Dark Ritual | B | 延迟秒杀 | water | 延迟后秒杀范围内怪物 |
| Nova | N | 爆发 AOE | water | 自身圆形冰冻爆发 |
| Stone Enchanted | 被动 | 被动 | earth | 被攻击时概率石化敌人 |
| Ball Lightning | I | 召唤 | air | 银球自动攻击附近敌人 |
| Chain Lightning | O | 投射物 | air | 连锁闪电，弹跳攻击 |

### 4.2 技能数据来源

所有技能数据（冷却、伤害、法力消耗）由各技能脚本自行管理，数据来自原版 `SpellBalance.txt`。

### 4.3 技能升级

- **等级范围**: 0~10 级（0 级 = 未学习）
- **技能点获得**: 每升 1 级获得 1 技能点
- **初始状态**: Magic Missile 默认为 1 级，其他技能初始未学习

### 4.4 冷却系统

- **独立冷却**: 每个技能各自独立冷却，互不干扰
- **长按持续施法**: 按住技能键可持续施放（受冷却限制）

---

## 5. 怪物系统

### 5.1 怪物种类（7种）

| ID | 怪物名称 | 类型 | 攻击方式 | 出现等级 |
|:--:|:---------|:----|:---------|:--------:|
| 0 | **Troll** (Rig) | 近战 | 近战攻击，40px 范围 | 1 |
| 1 | **Spider** | 近战 | 近战攻击，40px 范围 | 6 |
| 2 | **Blood Demon** | 近战 | 近战攻击，追击时 +40% 速度 | 14 |
| 3 | **Bear** | 近战 | 近战攻击，40px 范围 | 18 |
| 4 | **Mummy** (Archer) | 远程 | 弓箭射击，保持距离 | 3 |
| 5 | **Reaper** | 远程 | 3 枚火焰弹，保持距离 | 26 |
| 6 | **Diablo** (Boss) | 召唤 | 不直接攻击，每 5 秒召唤 4 只怪物 | 35 |

### 5.2 怪物基础参数

| 属性 | 说明 |
|:----|:-----|
| `health_per_level` | 每级生命值 = `hits_per_level * level` |
| `damage_base` | 基础伤害 |
| `damage_per_level` | 每级伤害增长 |
| `speed_base` | 基础移动速度 |
| `speed_per_level` | 每级速度增长 |
| `attack_rate` | 攻击间隔（秒） |
| `detection_range` | 索敌范围（近战 400px，远程 500px） |
| `attack_range` | 攻击范围（近战 40px，远程 300~380px） |
| `min_distance` | 最小保持距离（近战 40px，远程 150px） |
| `rotation_speed` | 转向速度（0.4~1.5） |
| `collision_damage` | 碰撞伤害 |
| `experience_reward` | 经验值奖励 |

### 5.3 怪物数据库详细数值

#### Troll（Troll/Rig）
| 属性 | 值 |
|:----|:--|
| experience | 30 |
| attack_rate | 2.0 |
| health_per_level | 7.0 |
| damage_base | 5.0 |
| damage_per_level | 1.0 |
| speed_base | 60.0 |
| speed_per_level | 0.85 |
| rotation_speed | 0.5 |
| attack_range | 40px |
| detection_range | 400px |
| collision_damage | 2.0 |

#### Spider
| 属性 | 值 |
|:----|:--|
| experience | 40 |
| attack_rate | 2.0 |
| health_per_level | 10.0 |
| damage_base | 6.0 |
| damage_per_level | 1.5 |
| speed_base | 60.0 |
| speed_per_level | 0.9 |
| rotation_speed | 0.75 |
| attack_range | 40px |
| detection_range | 400px |
| collision_damage | 2.0 |

#### Mummy（Archer）
| 属性 | 值 |
|:----|:--|
| experience | 50 |
| attack_rate | 2.0 |
| health_per_level | 4.0 |
| damage_base | 4.0 |
| damage_per_level | 1.25 |
| speed_base | 65.0 |
| speed_per_level | 0.95 |
| rotation_speed | 1.5 |
| attack_range_min | 150px |
| attack_range_max | 300px |
| detection_range | 500px |
| collision_damage | 0.0 |

#### Blood Demon
| 属性 | 值 |
|:----|:--|
| experience | 60 |
| attack_rate | 2.0 |
| health_per_level | 8.0 |
| damage_base | 8.0 |
| damage_per_level | 2.0 |
| speed_base | 60.0 |
| speed_per_level | 0.95 |
| rotation_speed | 0.4 |
| attack_range | 40px |
| detection_range | 400px |
| collision_damage | 3.0 |
| **特殊** | 追击时速度 +40% |

#### Bear
| 属性 | 值 |
|:----|:--|
| experience | 70 |
| attack_rate | 2.0 |
| health_per_level | 9.0 |
| damage_base | 10.0 |
| damage_per_level | 2.5 |
| speed_base | 65.0 |
| speed_per_level | 0.9 |
| rotation_speed | 0.6 |
| attack_range | 40px |
| detection_range | 400px |
| collision_damage | 5.0 |

#### Reaper
| 属性 | 值 |
|:----|:--|
| experience | 80 |
| attack_rate | 5.0 |
| health_per_level | 10.0 |
| damage_base | 4.0 |
| damage_per_level | 1.5 |
| speed_base | 60.0 |
| speed_per_level | 0.9 |
| rotation_speed | 1.5 |
| attack_range_min | 150px |
| attack_range_max | 340px |
| detection_range | 500px |
| collision_damage | 2.0 |

#### Diablo
| 属性 | 值 |
|:----|:--|
| experience | 200 |
| attack_rate | 15.0 |
| health_per_level | 25.0 |
| damage_base | 0.0 |
| damage_per_level | 0.0 |
| speed_base | 55.0 |
| speed_per_level | 0.85 |
| rotation_speed | 1.5 |
| attack_range_min | 150px |
| attack_range_max | 380px |
| detection_range | 500px |
| collision_damage | 8.0 |
| **特殊** | 不攻击，每 5 秒召唤 4 只怪物 |

### 5.4 怪物等级缩放公式

```
health = health_per_level * level
speed  = speed_base + speed_per_level * level
damage = damage_base + damage_per_level * level
```

### 5.5 怪物行为

#### 近战行为（Troll, Spider, Demon, Bear）
1. **游荡**: 从地图边缘生成，向直线方向游荡
2. **索敌**: 玩家进入 `detection_range` → 追击
3. **追击**: 向玩家移动，`rotation_speed` 控制转向灵活度
4. **攻击**: 进入 `attack_range` (40px) → 发动近战攻击
5. **保持距离**: 小于 `min_distance` (40px) 时停止移动避免穿模
6. **丢失目标**: 玩家离开检测范围 → 恢复游荡状态

#### 远程行为（Mummy, Reaper）
1. **游荡**: 从地图边缘生成，向直线方向游荡
2. **索敌**: 玩家进入 `detection_range` → 追击
3. **追击**: `optimal_range ~ detection_range` 之间时向玩家移动
4. **攻击**: 到达 `optimal_range` 内 → 停止移动，开始攻击
5. **攻击周期**: 前摇 0.5s → 发射 → 后摇 1.5s
6. **逃跑**: 玩家小于 `too_close_range` (150px) → 反向逃跑
7. **丢失目标**: 超出检测范围 → 停止追击

#### Diablo 特殊行为
1. **不直接攻击**: 不执行近战/远程攻击
2. **保持距离**: 玩家小于 200px 时后退，300px 左右停留
3. **召唤**: 每 15 秒召唤 4 只怪物（上下左右各 100px）
4. **召唤概率**: Reaper 5%, Demon 10%, Bear 15%, Mummy 20%, Spider 25%, Troll 25%

### 5.6 怪物转向速度

| 怪物 | rotation_speed | 转向风格 |
|:----|:--------------:|:---------|
| Demon | 0.4 | 笨重缓慢（2 秒转 180°） |
| Troll | 0.5 | 慢慢转身 |
| Bear | 0.6 | 中等转身 |
| Spider | 0.75 | 比较灵活 |
| Mummy | 1.5 | 瞬间转身 |
| Reaper | 1.5 | 瞬间转身 |
| Diablo | 1.5 | 瞬间转身 |

### 5.7 死亡与掉落

- 怪物死亡时，由 `LootManager` 根据掉落表判定是否生成拾取物品
- 同时通过信号 `tree_exited` 通知生成器计数减一

---

## 6. 怪物刷新方式系统

### 6.1 地图参数

- **地图大小**: 2560 × 2560 像素
- **安全边界**: 80px（怪物生成在边界内侧，避免卡墙）
- **英雄出生点**: (1280, 1280) — 地图中心

### 6.2 生成模式类型

原版游戏反编译出四种独立定时器的生成模式：

```gdscript
enum SpawnPattern { SINGLE, LINE, GROUP, ALL_SIDES }
```

### 6.3 模式①：单个生成（SINGLE）

| 参数 | 值 |
|:----|:--|
| **触发间隔** | 1~3 秒 |
| **生成数量** | 1 只 |
| **怪物选择** | 所有可用怪物（按权重） |
| **生成位置** | 地图边缘随机位置 |
| **游荡方向** | 随机方向 |
| **排除规则** | 无 |

**流程**:
1. 通过 `pick_monster_for_level()` 按权重选择怪物
2. 从四条边中随机选一条，随机位置生成
3. 怪物获得随机游荡方向，直线游荡

### 6.4 模式②：整排生成（LINE）

| 参数 | 值 |
|:----|:--|
| **触发间隔** | 18~22 秒 |
| **生成数量** | 20 只 |
| **怪物选择** | 排除 reaper 和 diablo |
| **生成位置** | 某条边均匀铺开 |
| **游荡方向** | 垂直于该边指向地图内侧 |
| **排除规则** | reaper, diablo |

**流程**:
1. 随机选一条边（上/下/左/右）
2. 沿该边均匀分布 20 个生成点
3. 所有怪物获得相同的"指向地图内侧"的游荡方向
4. 例如从下方生成 → 全部往上方游荡（横扫效果）

### 6.5 模式③：编组生成（GROUP）

| 参数 | 值 |
|:----|:--|
| **触发间隔** | 8~12 秒 |
| **编组大小** | 2×2(4只), 3×2(6只), 3×3(9只) |
| **概率分布** | 3×3 : 3×2 : 2×2 = 1 : 2 : 3 |
| **怪物选择** | 排除 diablo |
| **生成位置** | 某条边缘 |
| **游荡方向** | 垂直指向地图内侧 |
| **排除规则** | diablo |

**编组概率**:
- `roll = randi() % 6`
- `roll < 1` (1/6): 3×3 编组（9 只）
- `roll < 3` (2/6): 3×2 编组（6 只）
- `else` (3/6): 2×2 编组（4 只）

### 6.6 模式④：全边界生成（ALL_SIDES）

| 参数 | 值 |
|:----|:--|
| **触发间隔** | 38~42 秒 |
| **每边生成** | 15 只 |
| **总数** | 60 只（四边同时） |
| **解锁条件** | 英雄 ≥ 9 级 |
| **Quest 模式** | 英雄 ≥ 17 级（关卡5前不触发） |
| **怪物选择** | 排除 reaper 和 diablo |
| **游荡方向** | 各边垂直于边缘指向内侧 |
| **排除规则** | reaper, diablo |

### 6.7 怪物权重系统

每种怪物有基础权重，生成时只计算当前等级**可用**的怪物权重总和，归一化概率：

```gdscript
const MONSTER_WEIGHTS := {
    "troll":  25,    # 25.8% (35级后)
    "mummy":  22,    # 22.7%
    "spider": 18,    # 18.6%
    "demon":  15,    # 15.5%
    "bear":   10,    # 10.3%
    "reaper":  5,    #  5.2%
    "diablo":  2,    #  2.1%
}
```

总和 = 97，各模式排除的怪物不计入权重池。

### 6.8 Diablo 数量限制

- 同一时间场上最多 3 只 Diablo
- 超过限制则不生成新的 Diablo
- Diablo 死亡（`tree_exited`）后释放名额

### 6.9 游荡行为

所有怪物的游荡行为统一为：

1. **生成时获得**一个游荡方向（向量）
2. **直线行走**：沿该方向以 `move_speed` 速度前进
3. **碰墙反弹**：碰到地图边界时，像光线反射一样反弹（X/Y轴速度分别取反）
4. **索敌中断**：玩家进入 `detection_range` → 切换为追击状态
5. **丢失目标**：玩家离开检测范围 → 恢复游荡状态

---

## 7. 怪物光环系统

### 7.1 光环类型

每个怪物生成时有 50% 概率获得一种元素光环：

| 光环类型 | 颜色 | 减免的伤害属性 |
|:---------|:----:|:-------------:|
| basic | 紫色 | basic 属性伤害 |
| earth | 土黄色 | earth 属性伤害 |
| air | 白色 | air 属性伤害 |
| fire | 红色 | fire 属性伤害 |
| water | 蓝色 | water 属性伤害 |

### 7.2 光环效果

- **减伤比例**: 50%（`AURA_RESISTANCE = 0.5`）
- **触发条件**: 怪物受到与光环匹配的属性伤害时
- **视觉效果**: 怪物周围显示对应颜色的圆环（半径 20px，宽度 4px，层级 11）

### 7.3 光环分配逻辑

```gdscript
if randf() < 0.5:    # 50% 概率获得光环
    elemental_aura = random(["basic", "earth", "air", "fire", "water"])
else:                 # 50% 概率无光环
    elemental_aura = ""
```

---

## 8. 掉落物系统

### 8.1 掉落概率

- **基础掉落率**: 10%（`BASE_DROP_CHANCE = 0.10`）
- **受 Fortuna 技能影响**: `实际掉率 = 0.10 * Global.drop_rate_multiplier`
- 每次击杀只判定一次掉落

### 8.2 物品稀有度

| 稀有度 | 权重 | 掉率（基础） | 包含物品 |
|:-------|:---:|:-----------:|:---------|
| COMMON | 40 | 4% | Health Potion, Mana Potion |
| UNCOMMON | 30 | 3% | Rejuvenation, Quad Damage |
| UNIQUE | 15 | 1.5% | Physic Shield, Magic Shield |
| RARE | 10 | 1% | Speed Boots, Invulnerability, Free Spells |
| EXCEPTIONAL | 5 | 0.5% | Tome of Experience, Attribute Point, Skill Point |

### 8.3 拾取机制

- 物品通过 `PickupItem` 场景实现
- **普通拾取**: 玩家靠近物品自动拾取
- **Telekinesis 拾取**: 鼠标悬停物品上，按住等待蓄力条满即可远程拾取
- **物品持续时间**: 10 秒后自动消失

### 8.4 掉落物类型

| 物品 ID | 名称 | 效果 | 持续时间 |
|:-------:|:----|:-----|:--------:|
| 0 | Health Potion | 恢复生命 | 瞬时 |
| 1 | Mana Potion | 恢复法力 | 瞬时 |
| 2 | Rejuvenation | 恢复生命 + 法力 | 瞬时 |
| 3 | Quad Damage | 四倍伤害 | 15 秒 |
| 4 | Physic Shield | 物理抗性 20% | 15 秒 |
| 5 | Magic Shield | 魔法抗性 20% | 15 秒 |
| 6 | Speed Boots | 加速 | 15 秒 |
| 7 | Invulnerability | 无敌 | 15 秒 |
| 8 | Free Spells | 免费施法（不耗蓝） | 15 秒 |
| 9 | Tome of Experience | 获得经验值 | 瞬时 |
| 10 | Attribute Point | 获得 1 属性点 | 瞬时 |
| 11 | Skill Point | 获得 1 技能点 | 瞬时 |

### 8.5 物品掉落概率等级分布

原版数据中物品掉落随英雄等级提升：

| 参数 | 值 |
|:----|:---|
| PROBABILITY_ITEM | 0.1（基础 10%） |
| PROBABILITY_ITEM_LEVEL_1 | 0.4（40% 概率为 1 级物品） |
| PROBABILITY_ITEM_LEVEL_2 | 0.7 |
| PROBABILITY_ITEM_LEVEL_3 | 0.85 |
| PROBABILITY_ITEM_LEVEL_4 | 0.95 |
| PROBABILITY_ITEM_LEVEL_5 | 1.0 |

---

## 9. Buff/Debuff 系统

### 9.1 系统架构

所有临时效果通过统一的 buff 系统管理，存储在 `Global.hero_buffs` 字典中。

### 9.2 Buff 结构

```gdscript
{
    "id": "buff_id",         # 唯一标识
    "type": "buff"/"debuff", # 类型
    "category": "xxx",       # 类别（movement/defense/combat/regeneration/magic/special）
    "description": "xxx",    # 描述
    "duration": 5.0,         # 总持续时间
    "remaining": 5.0,        # 剩余时间
    "params": {}             # 自定义参数
}
```

### 9.3 预定义 Buff 模板

| Buff ID | 类型 | 类别 | 兼容层变量 |
|:--------|:----|:----|:----------|
| health_regen | buff | regeneration | — |
| mana_regen | buff | regeneration | — |
| speed_boost | buff | movement | `speed_multiplier` |
| damage_boost | buff | combat | `damage_multiplier` |
| magic_shield | buff | defense | `magic_resist` |
| physic_shield | buff | defense | `physic_resist` |
| free_spells | buff | magic | `free_spells` |
| invulnerability | buff | defense | `invulnerable` |
| hit_slow | debuff | movement | — |
| time_stop | buff | special | `time_stop_active` |
| heal | buff | regeneration | — |
| prayer | buff | regeneration | — |

### 9.4 Buff 兼容层

通过兼容层变量快速访问常用 buff 状态：

```gdscript
var damage_multiplier := 1.0     # 伤害倍率
var speed_multiplier := 1.0      # 速度倍率
var physic_resist := 0.0         # 物理抗性
var magic_resist := 0.0          # 魔法抗性
var free_spells := false         # 免费施法
var invulnerable := false        # 无敌
var drop_rate_multiplier := 1.0  # 掉落率倍率
var time_stop_active := false    # 时间停止
```

### 9.5 Buff 持续时间（原版数据）

| 效果 | 持续时间 |
|:----|:--------:|
| 物理抗性 (Physic Shield) | 15 秒 |
| 魔法抗性 (Magic Shield) | 15 秒 |
| 四倍伤害 (Quad Damage) | 15 秒 |
| 加速 (Speed Boost) | 15 秒 |
| 无敌 (Invulnerability) | 15 秒 |
| 时间停止 (Time Stop) | 15 秒 |

---

## 10. 存档系统

### 10.1 技术方案

- **存储格式**: JSON（`FileAccess` + `JSON.stringify`）
- **存档位置**: `user://saves/save_X.json`
- **存档槽位**: 1~9 号槽位
- **存档版本**: `CURRENT_VERSION = "1.0"`

### 10.2 快捷键

| 按键 | 操作 |
|:----|:-----|
| **F5** | 保存游戏到槽位 1 |
| **F10** | 从槽位 1 读取存档 |

### 10.3 存档内容

| 数据分类 | 保存内容 |
|:---------|:---------|
| 版本信息 | 存档格式版本号、时间戳 |
| 游戏设置 | 难度、游戏模式 |
| 英雄状态 | 等级、经验值、生命值、法力值、位置 |
| 属性 | 力量、敏捷、耐力、智力、智慧、属性点、技能点 |
| 技能 | 21 个技能的等级 |
| 快捷槽位 | LMB/RMB/Shift/Space 四个槽位的技能ID |
| Buff 状态 | 伤害倍率、速度倍率、物理抗性、魔法抗性、免费施法、无敌 |

### 10.4 读档流程

1. 清理所有现有怪物（`monsters` 分组）
2. 重置刷怪器计数器（`monster_spawners` 分组）
3. 清理所有掉落物（`pickup_items` 分组）
4. 重置英雄技能冷却
5. 从 JSON 恢复所有数据
6. 重新计算衍生属性
7. 恢复 Buff 兼容层变量
8. 发射信号通知 UI 更新

### 10.5 兼容性

- 旧版本存档（无位置、无 buff 字段）也能正常读取
- 缺失的字段自动忽略，使用当前默认值

---

## 11. UI/UX 系统

### 11.1 HUD 布局（2026-05-13 重构）

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
│ │ [技能栏: 图标1..8] [LMB][RMB]    │ │
│ │                   [Shf][Spc]    │ │
│ ├──────────────────────────────────┤ │
│ │████████████████████████████████░░│ │
│ │          LEVEL 10                │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

**节点结构**：
```
HUD (Control)
├── DamageOverlay (ColorRect) — 受击红晕
├── BuffContainer (HBoxContainer) — Buff/Debuff图标
└── BottomBar (Panel) — 高度86px
    ├── LeftInfo (VBoxContainer)
    │   ├── LevelLabel — "Lv.X"
    │   ├── HPBar — 血条
    │   └── MPBar — 蓝条
    ├── SkillBar (HBoxContainer) — 8个技能按钮（34×34px，间距2px）
    ├── QuickSlots (Control) — 2×2快捷槽位网格（46×30px面板）
    ├── ExpBar (ProgressBar) — 通栏经验条（全宽）
    └── ExpLabel (Label) — "LEVEL X" 居中文字
```

### 11.2 暂停菜单（PauseMenu）

- **触发**: ESC 键（`pause_game` 输入动作）
- **场景**: `Scenes/PauseMenu.tscn`
- **脚本**: `Scripts/pause_menu.gd`
- **功能**:
  - Resume — 继续游戏
  - Save Game — 保存游戏（F5）
  - Load Game — 读取存档（F10）
  - Return to Menu — 返回主菜单
  - Quit Game — 退出游戏
- **技术细节**:
  - `process_mode = 3`（WHEN_PAUSED）确保暂停时仍能处理输入
  - layer = 100，显示在最上层
  - 与 HeroPanel 互斥（通过 Global 标志控制）

### 11.3 死亡画面（GameOverScreen）

- **触发**: 英雄死亡（`hero_died` 信号）
- **场景**: `Scenes/GameOverScreen.tscn`（动态创建覆盖层）
- **脚本**: `Scripts/game_over_screen.gd`
- **显示内容**:
  - Quest 模式: 关卡号、击杀数、等级
  - Survival 模式: 等级、累积经验值（`Global.survival_total_exp_gained`）
- **操作**: Retry（重试）/ Return to Menu（返回主菜单）

### 11.4 关卡完成画面（LevelCompleteScreen）

- **触发**: Quest 模式通关（达到经验上限 + 清除所有怪物）
- **场景**: `Scenes/LevelCompleteScreen.tscn`（动态创建覆盖层）
- **脚本**: `Scripts/level_complete_screen.gd`
- **显示内容**: 关卡号、击杀数、等级
- **操作**: Continue（进入下一关）
- **特殊**: 第10关完成后跳转到 VictoryScreen

### 11.5 通关画面（VictoryScreen）

- **触发**: Quest 模式全部10关通关
- **场景**: `Scenes/VictoryScreen.tscn`（独立场景）
- **脚本**: `Scripts/victory_screen.gd`
- **显示内容**: 祝贺文字
- **操作**: Return to Menu（清除 Quest 进度，返回主菜单）

### 11.6 技能栏冷却显示（CooldownOverlay）

- **控件**: `Scripts/cooldown_overlay.gd`
- **效果**: 灰色扇形遮罩覆盖在技能图标上
- **实现**: 基于 Control 的 `draw_polygon` 绘制扇形
- **峰值检测**: 首次观察到冷却值时记录为峰值，后续更高值更新峰值
- **冷却结束**: 重置峰值为0，扇形消失
- **映射**: HUD 技能ID到 hero.skill_cooldowns key 的映射在 `SKILL_COOLDOWN_KEY_MAP` 中

### 11.7 怪物信息切换（Alt键）

- **触发**: 左 Alt 键（`toggle_monster_health` 输入动作）
- **状态**: `Global.show_monster_info`（布尔值）
- **开启时**:
  - 所有存活怪物的血条一直可见
  - 怪物受到伤害时显示黄色伤害数字（向上飘动0.8秒后消失）
- **关闭时**:
  - 血条仅在怪物受伤时短暂显示
  - 不显示伤害数字
- **新怪物**: 根据当前 `Global.show_monster_info` 状态决定血条初始可见性

### 11.8 受击红晕（Damage Vignette）

- **触发**: 英雄血量低于50%
- **实现**: ColorRect 定义在 HUD.tscn 中，运行时附加 ShaderMaterial
- **Shader**: 内联在 hud.gd 的 GDScript 字符串中，不依赖外部文件
- **效果**: 径向渐变（vignette）
  - 画面中心半径 25% 范围内完全透明
  - 从中间到边缘红色渐深
  - `pow(distance, 2.0)` 曲线使过渡自然
- **强度控制**: `_update_damage_overlay()` 控制 shader intensity 参数
  - 血量 > 50%: intensity = 0（完全透明）
  - 血量 ≤ 50%: intensity 从 0 → 1.0 线性增加

### 11.9 Survival 模式经验追踪

- **变量**: `Global.survival_total_exp_gained`
- **累加**: 每次获得经验时在 hero.gd 中累加
- **重置**: 新一局 Survival 开始时重置为0
- **显示**: 死亡时 GameOverScreen 显示 "EXPERIENCE GAINED: X"

### 11.10 快捷槽位系统（Quick Slots）

- **槽位数量**: 4个（LMB、RMB、Shift、Space）
- **布局**: 2×2 网格，位于技能栏右侧
  - 上排：LMB（左键）、RMB（右键）
  - 下排：Shift、Space
- **面板尺寸**: 46×30px，图标 42×26px 居中
- **快捷键提示**: 每个槽位右下角有半透明小字（LMB/RMB/Shift/Space）
- **位置**: QuickSlots 底部缩进 offset_bottom=-14，与 ExpBar 保持 2px 间距

**分配方式**：
| 槽位 | 分配方式 | 说明 |
|:-----|:---------|:-----|
| LMB | 点击技能图标（鼠标左键） | 在技能栏图标上点击左键 |
| RMB | 点击技能图标（鼠标右键） | 在技能栏图标上点击右键 |
| Shift | 悬浮 + 按 Shift 键 | 鼠标悬浮在技能图标上，按 Shift |
| Space | 悬浮 + 按 Space 键 | 鼠标悬浮在技能图标上，按 Space |

**技术实现**：
- `Global.gd`：`quick_slot_lmb/rmb/shift/space` 四个字符串变量存储技能ID
- `hud.gd`：`hovered_skill_id` 追踪鼠标悬浮的技能，`_input()` 处理 Shift/Space 分配
- `hero.gd`：`_get_quick_slot_skill()` 根据槽位名获取技能ID，`_cast_skill_by_id()` 统一施法
- `save_manager.gd`：快捷槽位配置随存档保存/读取
- `project.godot`：`spell_shift` 和 `spell_space` 输入映射（物理键码 KEY_SHIFT / KEY_SPACE）

**节点结构**：
```
QuickSlots (Control, offset_bottom=-14)
├── SlotLMB (Panel, 46×30)
│   ├── SlotLMBIcon (TextureRect, 42×26)
│   └── SlotLMBLabel ("LMB", 右下角7px小字)
├── SlotRMB (Panel, 46×30)
│   ├── SlotRMBIcon (TextureRect, 42×26)
│   └── SlotRMBLabel ("RMB")
├── SlotShift (Panel, 46×30)
│   ├── SlotShiftIcon (TextureRect, 42×26)
│   └── SlotShiftLabel ("Shift")
└── SlotSpace (Panel, 46×30)
    ├── SlotSpaceIcon (TextureRect, 42×26)
    └── SlotSpaceLabel ("Space")
```
