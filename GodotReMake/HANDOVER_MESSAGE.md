# Evil Invasion Remake — 交接提示词（发给下一个 Agent）

> **项目**: Evil Invasion (2006年Flash游戏) Godot 4.6 重制版
> **引擎**: Godot 4.6.2
> **GitHub**: https://github.com/54Lynnn/E_I_RMK_2
> **日期**: 2026-05-13

---

## 快速开始

1. `git clone` 后在 Godot 4.6.2 中导入 `GodotReMake/` 项目
2. 运行 `Scenes/Main.tscn`（Survival模式）或先运行 `GameModeSelect.tscn`
3. 按 **F2** 进入 DevMode（+100属性点+100技能点方便测试）
4. 按 **T** 打开技能树，给技能升级

---

## 必读文档（按优先级）

1. **`HANDOVER_PROMPT.md`** ← 最重要！项目完整状态、关键注意事项
2. **`DEVELOPER_HANDOVER.md`** — 完整项目文档、核心系统详解
3. **`GAME_SYSTEMS_DESIGN.md`** — 游戏系统设计
4. **`ROADMAP.md`** — 开发路线图
5. **`evil_invasion_spell.xlsx`** — 技能数值唯一可信来源

---

## 本次会话完成的工作（v6 Agent: 地图比例修正v2 + 质感到位 + 数值统一管理）

### 📐 地图比例修正v2（最终版）
- **地图 1536×1536**（=1024×1.5）— 用户用魔法飞弹法实测，10秒跑到边界，与原版9秒非常接近
- **摄像机边界限制**：玩家走到边缘时摄像机停在地图边界，不露空白
- **摄像机视口padding=100px**：怪物在地图边缘80px处生成，画面外走入视野
- **英雄加速度**：1200→700，起步转向更有惯性感
- **地面 Ground scale**：8→12

### 🎯 怪物数值统一管理
- **删除了 `_ready()` 中重复的 `_load_data_from_database()`**（生成器已统一调用）
- **清理了7个.tscn文件中的重复参数**（move_speed, health, damage, detection_range等）
- **所有数值改一个文件**：`monster_database.gd`
- 只保留怪物特有字段：Mummy的arrow_scene/optimal_range/too_close_range、Reaper的flame_scene、Diablo的frame_size

### 👾 怪物仇恨距离调整
| 怪物 | 原值 | 新值 |
|:----|:---:|:---:|
| Troll | 400 | **350** |
| Spider | 400 | **350** |
| Bear | 400 | **350** |
| Demon | 400 | **400** |
| Mummy/Reaper | 500 | **500**（optimal_range从500→**400**，有追击阶段了）|
| Diablo | 500 | **500** |

### 🎬 游戏质感到位
- **英雄待机帧**：站立时显示 hero_idle_0.png（不再冻在walk第0帧）
- **摄像机受击震动**：被攻击时画面轻震（强度3px，持续0.1s）
- **怪物死亡Aura淡出**：死亡时Aura与死亡动画同步淡出（1.28s）
- **升级光圈**：ColorRect→圆形Sprite2D，缩小尺寸（48px→24px半径）
- **爆炸/受击特效**：正方形→圆形（Explosion + ChainLightning命中特效）

### 🐛 Bug修复
- **SpeedBoost速度加成重复应用两次**：get_move_speed()内部已含speed_multiplier，移动计算又乘了一次 → 修复
- **英雄面板速度基数 100→65**：面板显示74（normal），与实际一致
- **英雄死亡动画重复播放**：添加 `if is_dying: return` 守卫
- **蜘蛛攻击身体消失**：蜘蛛攻击保留行走贴图，闪红代替
- **Mummy/Reaper侧面射击**：前摇阶段持续 `rotate_towards()`
- **Fireball爆炸半径**：LV1=60→56（与原版一致）
- **空指针**：$LevelLabel改为get_node_or_null安全访问

### 🎨 元素主题色统一
| 元素 | 原色 | 新色 | 备注 |
|:----|:----|:----|:------|
| Basic | #9370DB | **#C084FC** | 更紫粉 |
| Earth | #8B6914 | **#A08420** | 更偏黄，区分Fire |
| Air | #5BA3D9 | **#C8C8C8** | 银白色 |
| Fire | #D94A2A | 不变 | 红色 |
| Water | #3B8DBF | **#3B7FFF** | 更蓝 |

### 涉及文件（本次修改）
- `Scenes/Main.tscn` — 地图1536，英雄(768,768)，墙壁更新，Ground scale=12
- `Scenes/QuestMain.tscn` — 同上
- `Scripts/camera.gd` — 边界限制+shake+viewport_padding
- `Scripts/hero.gd` — 加速度700，待机帧，速度计算修复，死亡守卫，受击震动
- `Scripts/Monsters/monster_base.gd` — 删除重复加载，aura死亡淡出，蜘蛛攻击修复
- `Scripts/Monsters/monster_database.gd` — detection_range统一调整
- `Scripts/Monsters/monster_spawner.gd` — map_width/height 1024→1536
- `Scripts/Quest/quest_monster_spawner.gd` — map_width/height 1024→1536
- `Scripts/Spells/armageddon_zone.gd` — map_size 1024→1536
- `Scripts/Spells/explosion.gd` — 正方形→圆形
- `Scripts/Spells/chain_lightning_proj.gd` — 命中特效正方形→圆形
- `Scripts/Spells/fireball.gd` — 爆炸半径60→56
- `Scripts/Spells/skill_button.gd` — 元素主题色更新
- `Scripts/hero_panel.gd` — 速度基数100→65
- `Scenes/Mummy.tscn` — optimal_range=500→400，清理重复参数
- `Scenes/Reaper.tscn` — 新增optimal_range=400，清理重复参数
- `Scenes/Troll/Spider/Bear/Demon/Diablo.tscn` — 清理重复参数（保留特有字段）

---

## 建议下一步工作

1. **地图纹理** — 从Extracted_Textures/map_tex_X_1024x1024.dds转换PNG，替换绿色占位地面
2. **音效系统** — 68个OGG音效已提取，需一一对接到技能
3. **选项设置** — 音量/按键自定义/画面设置（优先级低）
4. **英雄面板UI进一步优化** — 暗色奇幻风布局已基本完成，可继续微调

---

## 重要约定

- 使用**中文**交流
- 技能数值以 `evil_invasion_spell.xlsx` 为准
- 一个技能一个场景的架构
- snake_case 命名变量/函数，PascalCase 命名场景文件
- 所有 .md 文档已更新到最新状态，请保持更新
- **所有怪物数值统一在 `monster_database.gd` 管理**
