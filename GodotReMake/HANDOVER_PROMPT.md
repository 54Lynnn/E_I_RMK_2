# Evil Invasion Remake — 新 Agent 交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-13
> **最新更新**: v7 Agent — 对象池系统 + 刷怪修复 + Data.pak全量提取
> **GitHub仓库**: https://github.com/54Lynnn/E_I_RMK_2

---

## 快速开始

1. 打开 Godot 4.6.2，导入项目 `GodotReMake/`
2. 运行主场景 `Main.tscn`
3. 按 F2 进入开发模式（获得100属性点+100技能点）
4. 按 T 打开技能树面板，给所有技能升级测试

---

## 当前项目状态（2026-05-13）

### 已完成 ✅

**核心系统**：
- [x] WASD移动 + 鼠标瞄准 + 独立冷却系统
- [x] 属性系统（5属性：力量/敏捷/耐力/智力/智慧）
- [x] 经验值简化公式（`exp_to_next = hero_level * 200`）
- [x] 开发模式（F2，+100属性点+100技能点）
- [x] 掉落系统（12种物品，5种稀有度）
- [x] **存档系统**（F5保存/F10读取，JSON格式）
- [x] **受击恢复系统**（被攻击后不能施法+减速20%）
- [x] **Buff/Debuff图标显示**
- [x] **游戏模式选择**（Survival / Quest）
- [x] **Quest模式**（10关线性推进、波次生成、等级上限、关卡选择器、存档持久化）

**UI/UX增强**：
- [x] **暂停菜单（PauseMenu）**：ESC打开，包含Resume/Save/Load/Return to Menu/Quit，游戏暂停
- [x] **死亡画面（GameOverScreen）**：显示关卡、击杀数、等级，提供Retry/Return to Menu
- [x] **关卡完成画面（LevelCompleteScreen）**
- [x] **通关画面（VictoryScreen）**
- [x] **技能栏冷却显示**：灰色扇形遮罩覆盖在技能图标上
- [x] **怪物信息显示（Alt键切换）**
- [x] **受击红晕（血量相关）**
- [x] **快捷槽位系统（4槽位）**：LMB/RMB/Shift/Space
- [x] **英雄面板UI优化**：暗色奇幻风布局，属性数值+评价显示，技能按钮元素系别颜色支持

**技能系统（21个，全部独立场景+独立脚本）**：
- [x] **数值来源**：`evil_invasion_spell.xlsx`
- [x] **全部 21 个技能已实现**
- [x] **元素系统**：5种元素（basic/earth/air/fire/water），技能按钮有对应颜色条
- [x] **Debuff系统**
- [x] **Global.hero_took_damage信号**

**怪物系统（7种）**：
- [x] **数据驱动**：所有数值统一在 `monster_database.gd` 管理（⚠️ 不再在 .tscn 设重复参数）
- [x] **统一边缘生成**：怪物从地图四边生成，游荡带墙壁反弹
- [x] **近战怪物**：Troll/Spider/Bear（detection_range=350），Demon（400，追击加速40%）
- [x] **远程怪物**：Mummy/Reaper（detection_range=500，optimal_range=400）
- [x] **特殊怪物**：Diablo（召唤者，detection_range=500）
- [x] **四种生成模式**：单个/整排/编组/全边界
- [x] **元素光环系统**：5种颜色与技能元素统一（Basic紫粉/Earth黄棕/Air银白/Fire红/Water蓝）

**动画系统 🎞️**：
- [x] **英雄行走**：16帧 spritesheet
- [x] **英雄待机**：hero_idle_0.png（站立不动时显示）
- [x] **英雄攻击/施法**：16帧 Attack1
- [x] **英雄死亡**：16帧 Death1，防重复播放
- [x] **怪物行走/攻击/死亡**：7种怪物全部 16帧 spritesheet
- [x] **动画状态机**：AnimState（WALK/ATTACK/DEATH）

**性能优化 🚀（v7 新增）**：
- [x] **对象池系统（ObjectPool）**：Autoload 单例，管理高频创建/销毁对象的复用
- [x] **池化对象**：Projectile(20)、MagicMissile(15)、NovaProj(10)、ChainLightningProj(10)、MonsterArrow(15)、ArmageddonZone(5)
- [x] **16个脚本已重构**使用对象池替代 instantiate/queue_free
- [x] **短命特效不池化**：Explosion/Armageddon闪光/MeteorSingle恢复为 instantiate（寿命<1s，收益低）

**怪物刷新修复 🎯（v7 新增）**：
- [x] **移除怪物数量上限**：原 `max_monsters=15` 硬上限已彻底删除
- [x] **4种生成模式无限制**：SINGLE/LINE/GROUP/ALL_SIDES 全部独立自由运转
- [x] **Diablo追踪修复**：从名字字符串匹配改为数组精确追踪
- [x] **计数器保护**：active_monsters 不会低于0，防存档加载时的延迟信号

**原版数据提取 🔬（v7 新增）**：
- [x] **Data.pak 全量提取**：92个文件全部通过 XOR 0xA5 解密
- [x] **MonsterBalance.txt**：7种怪物属性（血量/伤害/速度等）
- [x] **SpellBalance.txt**：21个技能数据（按玩家等级索引）
- [x] **HeroBalance.txt**：英雄属性系数
- [x] **ItemBalance.txt**：物品掉率/Buff持续时间
- [x] **MapDesc.txt**：8张地图名
- [x] **SpellDesc.txt**：技能描述英文原文

**比例修正 📐（v6 最终版）**：
- [x] **地图 1536×1536**（=1024×1.5，用户实测与原版速度相近）
- [x] **摄像机 zoom=1.0**
- [x] **摄像机边界限制**：玩家走到地图边缘时摄像机停在地图边界
- [x] **摄像机视口padding=100px**：怪物从画面外生成走入视野
- [x] **摄像机受击震动**：被怪物攻击时轻微震动（强度3px，持续0.1s）
- [x] **所有单位 scale=1**
- [x] **英雄加速度**：700（原1200，降低起步惯性感）

**原版贴图 🎨**：
- [x] 英雄/怪物动画帧已从原版提取并合成
- [x] Troll 绿色滤镜修复
- [x] 清理废弃占位文件

**Bug修复 🔧**：
- [x] SpeedBoost速度加成重复应用两次
- [x] 英雄面板速度显示基数 100→65
- [x] 英雄死亡动画重复播放
- [x] 蜘蛛攻击时身体消失
- [x] Mummy/Reaper侧面射击
- [x] 怪物死亡时Aura淡出
- [x] 升级光圈 ColorRect→圆形Sprite2D
- [x] 爆炸/受击反馈正方形→圆形
- [x] Fireball爆炸半径 LV1=60→56
- [x] Fireball/Firewalk技能ID命名不一致（fire_ball→fireball）
- [x] 升级空指针（get_node_or_null安全访问）
- [x] HeroPanel与底部HUD重叠
- [x] **怪物箭矢半路消失（_ready() 定时器残留）**
- [x] **投射物/特效对象池复用后 _ready() 不执行导致行为异常**

### 🔧 待完成

| 优先级 | 事项 | 说明 |
|:------:|:-----|:------|
| P1 | **主菜单** | 目前直接进入游戏模式选择 |
| P1 | **高分榜** | 原版有在线高分榜（对话框已提取参考） |
| P2 | **选项设置** | 音量/按键自定义/画面设置 |
| P3 | **地图纹理** | 6张 DDS 纹理已提取，最后做（纯美术资源） |
| P3 | **音效系统** | 68个OGG已提取，最后做（纯音频资源） |

---

## ⚠️ 关键注意事项

### 1. 地图与坐标系统（v6 更新！）
```
地图大小:  1536 × 1536 （=1024×1.5）
英雄出生点: (768, 768) （地图中心）
墙壁边界: 厚度32px
   左墙: (-16, 768)  范围 32×1536
   右墙: (1552, 768) 范围 32×1536
   上墙: (768, -16)  范围 1536×32
   下墙: (768, 1552) 范围 1536×32
Ground: scale=12 (128×12=1536)
```

### 2. 怪物数值统一管理（v6 新增！）
- **所有怪物数值在 `monster_database.gd` 中管理**（detection_range, health, damage, speed等）
- **.tscn 文件中不再保留重复参数**（除了怪物特有字段，如 Mummy 的 arrow_scene）
- 生成器（Spawner）统一调用 `apply_database_data()` 应用数值
- `_ready()` 中不再调用 `_load_data_from_database()`（避免重复加载）

### 3. 怪物刷怪系统（v7 重要更新！）
- **场上怪物数量无上限**：所有4种生成模式完全独立自由运转
- **唯一限制**：Diablo 同场最多3只（原版设定）
- **SINGLE模式**：每1~3秒在边缘生成1只随机怪物
- **LINE模式**：每18~22秒从某边生成20只同种怪物横扫
- **GROUP模式**：每8~12秒从边缘生成4~9只（2×2/3×2/3×3）编组
- **ALL_SIDES模式**：每38~42秒从四边各生成15只同种怪物（LV≥9解锁）
- **注意**：以上刷怪参数（间隔/数量/解锁等级）**来源不确定**，基于之前开发者的反编译理解，Data.pak 中无对应配置文件。建议根据实际游戏体验调整。

### 4. 对象池系统（v7 新增！）
- **Autoload 脚本**: `Scripts/object_pool.gd`
- **使用方法**：
  ```gdscript
  # 从池中获取对象
  var obj = ObjectPool.get_object(MyScene)
  obj.global_position = ...
  get_parent().add_child(obj)
  
  # 归还对象到池中（替代 queue_free）
  ObjectPool.return_to_pool(self)
  ```
- **池化规则**：
  - 使用 `_process()` 或 `_physics_process()` 管理生命周期的对象适合池化
  - 使用 `_ready()` 中 tween/timer 的短命特效（<1s）不适合池化
  - 池化对象必须实现 `reset_for_pool()` 方法重置所有状态
  - 不要依赖 `_ready()` 做状态初始化（复用后不执行），改用 `_process()` 首帧检测

### 5. 原版数据提取（v7 新增！）
- **提取工具**：`e:\EvilInvasion\extract_all.py`（Python脚本，XOR 0xA5解密）
- **提取位置**：`e:\EvilInvasion\extracted_all/`（92个已解密文件）
- **关键配置文件**：
  - `Scripts_MonsterBalance.txt` → 7种怪物属性（✅ 可信）
  - `Scripts_SpellBalance.txt` → 技能数据（⚠️ 按玩家等级索引，非技能等级）
  - `Scripts_HeroBalance.txt` → 英雄属性系数
  - `Scripts_ItemBalance.txt` → 物品掉落概率/持续时间
  - `Scripts_MapDesc.txt` → 8张地图名
- **注意**：
  - 4种刷怪模式的参数（间隔/数量）**不在Data.pak中**，来源不确定
  - 怪物权重系统（troll:25/mummy:22等）同样来源不确定

### 6. 摄像机设置（v6 更新！）
```gdscript
# camera.gd
zoom = Vector2(1.0, 1.0)
viewport_padding = 100.0  # 边界 padding，怪物从画面外生成
```
- 摄像机跟随目标 = lerp 平滑跟随
- **边界约束**：摄像机中心不会超出地图边界，画面不露空白
- **受击震动**：shake(3.0)，持续0.1秒自动复位

### 7. 远程怪物三层距离系统
| 参数 | 含义 | Mummy/Reaper 当前值 |
|:----|:-----|:------------------:|
| detection_range | 索敌追击距离 | 500 |
| optimal_range | 停下攻击的最远距离 | 400 |
| too_close_range | 逃跑距离（太近反向跑） | 150 |

行为：500以外wander→500~400追击→400~150停下攻击→<150逃跑

### 8. 近战怪物 detection_range
| 怪物 | 当前值 |
|:----|:------:|
| Troll/Spider/Bear | 350 |
| Demon | 400 |
| Mummy/Reaper/Diablo | 500 |

### 9. 英雄/怪物尺寸
```
英雄 Sprite2D: 原始 48×48，无额外 scale
怪物 Sprite2D: 原始 48×48（Diablo 64×64），无额外 scale
拾取物 Sprite2D: 原始 34×34，无 scale
投射物 Sprite2D: 48×48 × scale(0.35) ≈ 17×17
```

### 10. 技能数值来源
- **❌ 不要使用 `extracted.md` 的技能数据**（等级偏移错误）
- **❌ 不要使用 `SpellBalance.txt` 的原始数值**（按玩家等级索引，不是技能等级）
- **✅ 唯一可信来源**：`evil_invasion_spell.xlsx`
- 所有技能脚本中的数值公式已按 xlsx 数据实现

### 11. 文件路径
```
Scripts/
├── object_pool.gd      ← Autoload 对象池
├── Spells/             ← 所有技能脚本（21个）
├── Monsters/           ← 所有怪物脚本（7种）
│   ├── monster_base.gd          ← map_bounds = 1536
│   └── monster_database.gd      ← ← 所有数值在这里改！
├── Quest/              ← Quest模式相关脚本
└── ...
```

### 12. 英雄待机动画（v6 新增）
- **站立不动时**：显示 `hero_idle_0.png`
- **移动时**：切换为 `hero_walk.png` 16帧循环
- 切换时机在 `_update_walk_animation()` 中处理

### 13. hero.gd 速度计算（v6 修改！）
```gdscript
var target_velocity = input_dir * get_move_speed()  # get_move_speed() 内部已乘
```

### 14. 元素主题色（v6 统一）
| 元素 | 颜色 | 用途 |
|:----|:----|:------|
| Basic | #C084FC (紫粉) | 技能按钮条 + 怪物光圈 |
| Earth | #A08420 (黄棕) | 同上 |
| Air | #C8C8C8 (银白) | 同上 |
| Fire | #D94A2A (红) | 同上 |
| Water | #3B7FFF (蓝) | 同上 |

### 15. Ball Lightning 行为
- 在鼠标光标位置生成
- 生成点 130px 范围内随机游荡
- 检测 100px 内的敌人
- 攻击时蓝白色激光束特效
- 每次攻击间隔 1 秒，最多攻击 5 次
- 最大存活时间 10 秒

---

## 存档格式说明

- **存档位置**: `user://saves/save_X.json`
- **保存**: F5
- **读取**: F10
- **自动存档**: Quest 模式通关时自动保存

---

## 原版提取资源已就绪

`Extracted_Textures/` 目录中包含：
- `Textures_Scrap_RGBA.png` — 合成后的完整精灵图（2048×2048）
- `hero_frames/` — 英雄所有动画帧（82帧）
- `各怪物_frames/` — 怪物动画帧
- `map_tex_0~5_1024x1024.dds` — 6张地图纹理
- `sound_0~67.ogg` — 68个音效

`extracted_all/` 目录中包含（v7 新增）：
- 从 `Data.pak` 全量提取的92个解密文件
- 包括怪物/技能/物品/英雄的所有平衡配置
- 包括8个游戏界面的 UI 布局定义
