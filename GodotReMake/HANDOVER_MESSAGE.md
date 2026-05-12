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

1. **`HANDOVER_PROMPT.md`** ← 最重要！项目状态、关键注意事项、按钮绑定
2. **`DEVELOPER_HANDOVER.md`** — 完整项目文档、核心系统详解
3. **`GAME_SYSTEMS_DESIGN.md`** — 游戏系统设计（含快捷槽位系统）
4. **`SPELL_DEVELOPMENT_GUIDE.md`** — 技能开发规范（必须遵守）
5. **`ROADMAP.md`** — 开发路线图
6. **`NAMING_CONVENTIONS.md`** — 命名规范
7. **`evil_invasion_spell.xlsx`** — 技能数值唯一可信来源

---

## 本次会话完成的工作

### 快捷槽位系统（4槽位 2×2 网格）
- LMB/RMB/Shift/Space 四个可自定义快捷槽位
- 2×2 网格布局，位于技能栏右侧
- **分配方式**：
  - LMB/RMB：在技能栏图标上点击左键/右键
  - Shift/Space：鼠标悬浮在技能图标上，按 Shift/Space 键
- 槽位右下角有半透明快捷键小字提示
- 图标居中，无技能名称文字
- 快捷槽位配置随存档保存/读取（F5保存/F10读取）
- 底部缩进避免与 ExpBar 重叠

### 涉及文件
- `Scenes/HUD.tscn` — QuickSlots 节点（4个Panel + Icon + Label）
- `Scripts/hud.gd` — hovered_skill_id 追踪 + _input() 处理 Shift/Space 分配
- `Scripts/hero.gd` — _get_quick_slot_skill() + _cast_skill_by_id()
- `Scripts/global.gd` — quick_slot_lmb/rmb/shift/space 变量
- `Scripts/save_manager.gd` — 快捷槽位存档持久化
- `project.godot` — spell_shift / spell_space 输入映射

---

## 建议下一步工作

1. **音效系统** — 用户打算最后添加，暂不处理
2. **地图系统** — 原版有8张地图，目前只有1张测试图（2560×2560绿色地面）
3. **怪物贴图** — 所有怪物使用占位方块，需从原版 Data.pak 提取 DDS 纹理
4. **英雄贴图** — 英雄使用蓝色方块
5. **主菜单** — 目前直接进入游戏模式选择
6. **选项设置** — 音量/按键自定义/画面设置
7. **Quest模式Boss战** — 第10关 Diablo 需要特殊设计
8. **性能优化** — 对象池、内存管理

---

## 重要约定

- 使用**中文**交流
- 技能数值以 `evil_invasion_spell.xlsx` 为准，不要用 `extracted.md` 的数据
- 一个技能一个场景的架构
- snake_case 命名变量/函数，PascalCase 命名场景文件
- 所有 .md 文档已更新到最新状态，请保持更新