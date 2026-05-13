以下的交接文档将被发送给我的合作者、一个coding assistant。请你阅读，然后根据它的要求一步一步完成任务。

---

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

1. **`HANDOVER_PROMPT.md`** — 项目完整状态、关键注意事项、最新变更
2. **`HANDOVER_MESSAGE.md`** — 最新一次会话的详细工作报告
3. **`DEVELOPER_HANDOVER.md`** — 完整项目文档、核心系统详解
4. **`GAME_SYSTEMS_DESIGN.md`** — 游戏系统设计文档
5. **`ROADMAP.md`** — 开发路线图

## 开发约定

- 使用**中文**交流
- 技能数值以 `evil_invasion_spell.xlsx` 为准
- 一个技能一个场景的架构
- snake_case 命名变量/函数，PascalCase 命名场景文件
- 所有 .md 文档已更新到最新状态
- **所有怪物数值统一在 `monster_database.gd` 管理**，.tscn 中不再保留重复参数

## 原版提取资源

`Extracted_Textures/` 目录中存放了从原版 Data.pak 提取的所有资源：
- `hero_frames/` 及各类怪物 `_frames/` — 动画帧
- `map_tex_0~5_1024x1024.dds` — 6张地图纹理
- `sound_0~67.ogg` — 68个音效
- `Textures_Scrap_RGBA.png` — 合成后的完整精灵图（2048×2048）

## 建议下一步工作（按优先级）

1. **地图纹理** — 转换 DDS 为 PNG，替换当前绿色占位地面
2. **音效系统** — 68个OGG音效已提取，需对接到各技能
3. **选项设置** — 音量/按键自定义/画面设置（优先级低）
4. **英雄面板UI进一步优化** — 暗色奇幻风布局已基本完成，可继续微调
