# Evil Invasion 原版数据反编译文档

> ⚠️ **重要警告**：本文档中的技能数值表格（第四章）存在等级偏移错误，不可直接使用！
> 
> **所有技能数值请以 `E:\EvilInvasion\evil_invasion_spell.xlsx` 为准。**
> 
> Excel 文件中的数据是手动从原版游戏记录的正确数值，等级范围为 1-10（相对技能等级）。
> 本文档保留的其他信息（英雄属性、怪物数据、动画数据、音效列表等）仍然有效。

> 从 `Data.pak` 中使用 XOR 0xA5 解密提取
> 源文件位置: `Data.pak` 偏移 41783-141783

***

## 一、英雄属性系统 (HeroBalance.txt)

### 1.1 属性系数

| 属性                                   |  每点增加值 |  基础值 | 说明              |
| ------------------------------------ | :----: | :--: | --------------- |
| STRENGTH\_ON\_HEALTH                 |   +10  |   0  | 每点力量增加 HP 上限    |
| STRENGTH\_ON\_HIT\_RECOVERY          | -0.004 | 0.5s | 每点力量减少受击硬直时间（秒） |
| DEXTERITY\_ON\_SPEED                 |  +0.5  |  65  | 每点敏捷增加移动速度      |
| DEXTERITY\_ON\_CHANCE\_TO\_BE\_HIT   | -0.004 |  1.0 | 每点敏捷减少被命中几率     |
| STAMINA\_ON\_HEALTH\_REGENERATION    |  +0.1  |   0  | 每点耐力增加 HP 恢复/秒  |
| STAMINA\_ON\_SPEED                   |  +0.35 |   0  | 每点耐力增加移动速度      |
| INTELLIGENCE\_ON\_MANA               |   +6   |   0  | 每点智力增加 MP 上限    |
| INTELLIGENCE\_ON\_MANA\_REGENERATION |  +0.06 |   0  | 每点智力增加 MP 恢复/秒  |
| WISDOM\_ON\_MANA                     |   +2   |   0  | 每点智慧增加 MP 上限    |
| WISDOM\_ON\_MANA\_REGENERATION       |  +0.18 |   0  | 每点智慧增加 MP 恢复/秒  |

> COEFF = 0.167969, START\_VALUE = 0.734375（用于升级公式等计算）

### 1.2 英雄描述文本

属性面板中的说明文本：

| 字段                  | 说明                                                                                                                                                 |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Health              | "1 strength point increases by 10 health points."                                                                                                  |
| Health regeneration | "1 stamina point increases by 0.1 health point regeneration per second."                                                                           |
| Movement speed      | "1 dexterity point increases by 0.5 hero speed.\n1 stamina point increases by 0.35 hero speed."                                                    |
| Hit recovery        | "1 strength points decreases by 0.004 seconds hit recovery time.\nBase hit recovery time is 0.5 seconds."                                          |
| Chance to be hit    | "1 dexterity point decreases by 0.4% chance to be hit."                                                                                            |
| Mana                | "1 intelligence point increases by 6 hero mana capacity.\n1 wisdom point increases by 2 hero mana capacity."                                       |
| Mana regeneration   | "1 intelligence point increases by 0.06 mana point regeneration per second.\n1 wisdom point increases by 0.18 mana point regeneration per second." |

### 1.3 恢复/等级描述文本分级

extra slow, very slow, slow, normal, fast, very fast, extra fast

***

## 二、游戏常量

### 2.1 恢复时间

| 常量                     |  值  | 说明        |
| ---------------------- | :-: | --------- |
| HEALTH\_RECOVERY\_TIME |  5  | 生命恢复间隔(?) |
| MANA\_RECOVERY\_TIME   |  5  | 法力恢复间隔(?) |

### 2.2 Buff 持续时间

| Buff                 | 持续时间(秒) |
| -------------------- | :-----: |
| PHYSIC\_RESIST\_TIME |    15   |
| MAGIC\_RESIST\_TIME  |    15   |
| QUAD\_DAMAGE\_TIME   |    15   |
| SPEED\_TIME          |    15   |
| IMMUNE\_TIME         |    15   |
| TIME\_STOP\_TIME     |    15   |

### 2.3 减伤系数

| 系数                        |     值     |
| ------------------------- | :-------: |
| PHYSIC\_DAMAGE\_REDUCTION | 0.2 (20%) |
| MAGIC\_DAMAGE\_REDUCTION  | 0.2 (20%) |
| EXPERIENCE\_GIVE          |    0.2    |

### 2.4 物品掉落概率

| 等级 | 概率 |
| :--: | :--: |
| PROBABILITY_ITEM (基础) | 0.1 (10%) |

> ⚠️ **注意**：以下 LEVEL_1 到 LEVEL_5 的数据来源不明，可能是反编译错误，**请勿使用**。
> 原版游戏中怪物掉落率可能受 Fortuna 技能影响，具体加成方式请参考 `E:\EvilInvasion\evil_invasion_spell.xlsx` 中的 fortuna 数据。

### 2.5 物品存活时间

LIFE\_TIME = 10 秒

***

## 三、怪物属性 (MonsterBalance)

### 3.1 怪物数据总表

| 属性                 |  RIG | SPIDER | DEMON | BEAR | ARCHER | REAPER | BOSS |
| :----------------- | :--: | :----: | :---: | :--: | :----: | :----: | :--: |
| EXPERIENCE         |  30  |   40   |   60  |  70  |   50   |   80   |  200 |
| ATTACK\_RATE       |   2  |    2   |   2   |   2  |    2   |    5   |  15  |
| HITS\_BASE         |   0  |    0   |   0   |   0  |    0   |    1   |   0  |
| HITS\_PER\_LEVEL   |   7  |   10   |   8   |   9  |    4   |   10   |  25  |
| DAMAGE\_BASE       |   5  |    6   |   8   |  10  |    4   |    4   |   0  |
| DAMAGE\_PER\_LEVEL |   1  |   1.5  |   2   |  2.5 |  1.25  |    1   |   0  |
| SPEED\_BASE        |  60  |   60   |   60  |  65  |   65   |   60   |  55  |
| SPEED\_PER\_LEVEL  | 0.85 |   0.9  |  0.95 |  0.9 |  0.95  |   0.9  | 0.85 |
| ROTATION\_SPEED    |  0.5 |  0.75  |  0.4  |  0.6 |   1.5  |   1.5  |  1.5 |
| ATTACK\_RANGE\_MIN |   0  |    0   |   0   |   0  |   150  |   150  |  150 |
| ATTACK\_RANGE\_MAX |  200 |   180  |  220  |  260 |   300  |   340  |  380 |

### 3.2 怪物特性说明

- **RIG (骷髅)**: 基础近战怪，属性均衡
- **SPIDER (蜘蛛)**: 高速近战，攻速中等
- **DEMON (恶魔)**: 高伤害近战，速度较快
- **BEAR (熊)**: 高血量高伤害，但速度较慢
- **ARCHER (弓手)**: 远程攻击（射程150-300），攻击间隔2
- **REAPER (死神)**: 远程法力燃烧（射程150-340），攻速极快(ATTACK\_RATE=5)，HITS\_BASE=1
- **BOSS**: 极高经验(200)和血量，射程最远(380)，但攻击间隔极长(15)

### 3.3 怪物动画

每个怪物有独立的动画序列（WalkLegs, WalkTors, Attack1, Attack2, Death1, Death2, Frozen, Stoned），动画帧数为 16×16 像素，包含 Frozen（冰冻）和 Stoned（石化）状态动画。

***

## 四、技能数据 (SpellBalance)

> ⚠️ **已删除**：原反编译的技能数值表格存在等级偏移错误（将全局等级当作技能相对等级）。
> 
> **所有技能数值请以 `E:\EvilInvasion\evil_invasion_spell.xlsx` 为准。**
> 
> Excel 文件中包含以下技能的准确数值（等级 1-10）：
> - magic_missile, fireball, firewalk, heal, meteor, armageddon
> - freezing_spear, fortuna, poison_cloud, nova, dark_ritual
> - sacrifice, telekinesis, holy_light, ball_lightning, chain_lightning
> - prayer, mistfog, teleport, stone_enchanted, wrath_of_god

## 五、地图列表

地图名: Ancient Way, Burned Land, Desert Battle, Fogotten Dunes, Dark Swamp, Skull Coast, Snowy Pass, Hell Eye

> 对应纹理文件: `Textures\AcientWay.dds`, `Textures\BurnedLand.dds`, 等 (均为 1024×1024 DXT1)

***

## 六、动画数据 (UnitAnimDesc)

### 单位动画帧配置

每个单位包含 8 种动画状态:

- ANIMATION\_WALK\_LEGS - 行走腿部
- ANIMATION\_WALK\_TORS - 行走躯干
- ANIMATION\_ATTACK1 - 攻击1
- ANIMATION\_ATTACK2 - 攻击2
- ANIMATION\_DEATH1 - 死亡1
- ANIMATION\_DEATH2 - 死亡2
- FROZEN - 冰冻
- STONED - 石化

格式: `ANIMATION_TYPE "路径" 起始帧 帧宽 帧高`

单位列表: HERO, RIG, SPIDER, DEMON, BEAR, ARCHER (Mummy), REAPER, BOSS (Diablo)

***

## 七、音效文件

从 PAK 中提取了 68 个 OGG 音效文件，包含:

- 技能施放音效 (Magic Missile, Fireball, Meteor 等)
- 怪物音效 (Spider, Bear, Archer, Demon, Reaper, Rig, Boss 的攻击/死亡)
- 物品拾取音效
- 界面音效 (按钮点击、菜单滚动)
- 背景音乐 (Music.ogg)

***

> 最后更新: 2026-05-06
> 提取方式: Python 脚本解包 Data.pak + XOR 0xA5 解密

