# Evil Invasion Remake — 新 Agent 交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-13
> **最新更新**: v6 Agent — 地图比例修正v2 + 质感到位 + 数值统一管理
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
- [x] SpeedBoost速度加成重复应用两次（get_move_speed+移动计算各乘一次）
- [x] 英雄面板速度显示基数 100→65（与实际一致）
- [x] 英雄死亡动画重复播放（添加is_dying守卫）
- [x] 蜘蛛攻击时身体消失（保留行走贴图，闪红代替）
- [x] Mummy/Reaper侧面射击（前摇阶段持续转向玩家）
- [x] 怪物死亡时Aura淡出（与死亡动画同步）
- [x] 升级光圈 ColorRect→圆形Sprite2D（缩小尺寸）
- [x] 爆炸/受击反馈正方形→圆形
- [x] Fireball爆炸半径 LV1=56（原版数据）
- [x] Fireball/Firewalk技能ID命名不一致（fire_ball→fireball）
- [x] 升级空指针（get_node_or_null安全访问）
- [x] HeroPanel与底部HUD重叠（offset调整）

### 🔧 待完成

| 优先级 | 事项 | 说明 |
|:------:|:-----|:------|
| P1 | **主菜单** | 目前直接进入游戏模式选择 |
| P1 | **高分榜** | 原版有在线高分榜 |
| P1 | **对象池** | 大量投射物/怪物时性能优化 |
| P2 | **选项设置** | 音量/按键自定义/画面设置（优先级低） |
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

### 3. 摄像机设置（v6 更新！）
```gdscript
# camera.gd
zoom = Vector2(1.0, 1.0)
viewport_padding = 100.0  # 边界 padding，怪物从画面外生成
```
- 摄像机跟随目标 = lerp 平滑跟随
- **边界约束**：摄像机中心不会超出地图边界，画面不露空白
- **受击震动**：shake(3.0)，持续0.1秒自动复位

### 4. 远程怪物三层距离系统
| 参数 | 含义 | Mummy/Reaper 当前值 |
|:----|:-----|:------------------:|
| detection_range | 索敌追击距离 | 500 |
| optimal_range | 停下攻击的最远距离 | 400 |
| too_close_range | 逃跑距离（太近反向跑） | 150 |

行为：500以外wander→500~400追击→400~150停下攻击→<150逃跑

### 5. 近战怪物 detection_range
| 怪物 | 当前值 |
|:----|:------:|
| Troll/Spider/Bear | 350 |
| Demon | 400 |
| Mummy/Reaper/Diablo | 500 |

### 6. 英雄/怪物尺寸
```
英雄 Sprite2D: 原始 48×48，无额外 scale
怪物 Sprite2D: 原始 48×48（Diablo 64×64），无额外 scale
拾取物 Sprite2D: 原始 34×34，无 scale
投射物 Sprite2D: 48×48 × scale(0.35) ≈ 17×17
```

### 7. 技能数值来源
- **❌ 不要使用 `extracted.md` 的技能数据**（等级偏移错误）
- **✅ 唯一可信来源**：`evil_invasion_spell.xlsx`
- 所有技能脚本中的数值公式已按 xlsx 数据实现

### 8. 文件路径
```
Scripts/
├── Spells/          ← 所有技能脚本（21个）
├── Monsters/        ← 所有怪物脚本（7种）
│   ├── monster_base.gd        ← map_bounds = 1536
│   └── monster_database.gd    ← ← 所有数值在这里改！
├── Quest/           ← Quest模式相关脚本
└── ...
```

### 9. 英雄待机动画（v6 新增）
- **站立不动时**：显示 `hero_idle_0.png`
- **移动时**：切换为 `hero_walk.png` 16帧循环
- 切换时机在 `_update_walk_animation()` 中处理

### 10. hero.gd 速度计算（v6 修改！）
```gdscript
# 不再重复乘以 speed_multiplier！
var target_velocity = input_dir * get_move_speed()  # get_move_speed() 内部已乘
```

### 11. 元素主题色（v6 统一）
| 元素 | 颜色 | 用途 |
|:----|:----|:------|
| Basic | #C084FC (紫粉) | 技能按钮条 + 怪物光圈 |
| Earth | #A08420 (黄棕) | 同上 |
| Air | #C8C8C8 (银白) | 同上 |
| Fire | #D94A2A (红) | 同上 |
| Water | #3B7FFF (蓝) | 同上 |

### 12. Ball Lightning 行为
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
