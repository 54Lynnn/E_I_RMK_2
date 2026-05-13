# Evil Invasion Remake — 新 Agent 交接提示词

> **项目**: Evil Invasion (2006年Flash游戏) Godot 4.6 重制版
> **引擎**: Godot 4.6.2
> **GitHub**: https://github.com/54Lynnn/E_I_RMK_2
> **最新更新**: v7 Agent — 对象池系统 + 刷怪修复 + Data.pak全量提取

## 快速开始

1. `git clone` 后在 Godot 4.6.2 中导入 `GodotReMake/` 项目
2. 运行 `Scenes/Main.tscn`（Survival模式）或先运行 `GameModeSelect.tscn`
3. 按 **F2** 进入 DevMode（+100属性点+100技能点方便测试）
4. 按 **T** 打开技能树，给技能升级

## 必读文档

请依次阅读以下文档，它们包含了完整的项目信息：

1. **`HANDOVER_PROMPT.md`** — 项目完整状态、关键注意事项、最新变更（**最重要！**）
2. **`DEVELOPER_HANDOVER.md`** — 完整项目文档、核心系统详解
3. **`GAME_SYSTEMS_DESIGN.md`** — 游戏系统设计文档
4. **`ROADMAP.md`** — 开发路线图

---

## v7 会话完成的工作（2026-05-13）

### 🏊 对象池系统（性能优化）
- **新增 `Scripts/object_pool.gd`** — Autoload 单例，管理高频创建/销毁对象的复用
- **注册到 `project.godot`** — `ObjectPool="*res://Scripts/object_pool.gd"`
- **池化对象**: Projectile(20), MagicMissile(15), NovaProj(10), ChainLightningProj(10), MonsterArrow(15), ArmageddonZone(5)
- **16个脚本已改造**: 所有使用 `preload(...).instantiate()` + `queue_free()` 的投射物/箭矢改为对象池
- **短命特效不池化**: Explosion/Armageddon闪光/MeteorSingle 寿命<1s，恢复为 instantiate
- **池化协议**: 池化对象必须实现 `reset_for_pool()` 方法重置状态
- **不依赖 `_ready()`**: 池化对象的初始化不要放在 `_ready()` 中（复用后不执行），改用 `_process()` 首帧检测

### 🎯 怪物刷怪修复
- **彻底移除怪物数量上限**: 原来 `max_monsters=15` 的硬上限导致全场只有十几只怪物
- **4种模式无限制**: SINGLE/LINE/GROUP/ALL_SIDES 全部独立自由运转
- **Diablo 追踪修复**: 从 `monster.name.contains("diablo")` 改为数组精确追踪
- **计数器保护**: active_monsters 不会低于0

### 🔬 Data.pak 全量提取
- **提取工具**: `e:\EvilInvasion\extract_all.py`（Python 脚本，XOR 0xA5 解密）
- **92个文件全部解密**: 包括 MonsterBalance/SpellBalance/HeroBalance/ItemBalance/MapDesc/SpellDesc
- **提取位置**: `e:\EvilInvasion\extracted_all/`
- **关键发现**: 刷怪模式的参数（间隔/数量/解锁等级）**不在 Data.pak 中**，来源不确定

### 🐛 Bug修复
- **怪物箭矢半路消失**: `monster_arrow.gd` 的 `_ready()` 中定时器残留，箭从池中取出后旧定时器到期强收
- **对象池 `_ready()` 问题**: 排查并修复了所有池化对象的初始化策略

---

## 开发约定

- 使用**中文**交流
- 技能数值以 `evil_invasion_spell.xlsx` 为准
- 一个技能一个场景的架构
- snake_case 命名变量/函数，PascalCase 命名场景文件
- 所有 .md 文档已更新到最新状态
- **所有怪物数值统一在 `monster_database.gd` 管理**，.tscn 中不再保留重复参数
- **刷怪参数（间隔/数量/解锁等级）来源不确定**，建议根据游戏体验调整

## 建议下一步工作（按优先级）

1. **主菜单** — 目前直接进入游戏模式选择
2. **高分榜** — 原版有在线高分榜（对话框 UI 已从 Data.pak 提取参考）
3. **选项设置** — 音量/按键自定义/画面设置（优先级低）
4. **地图纹理** — 6张 DDS 纹理已提取，替换当前绿色占位地面
5. **音效系统** — 68个OGG已提取，需对接到各技能
