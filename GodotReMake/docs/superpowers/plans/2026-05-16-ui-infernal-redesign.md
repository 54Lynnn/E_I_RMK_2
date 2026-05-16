# UI Infernal 重设计 — 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 MainMenu、HeroPanel、HUD 升级为统一的 Infernal（Diablo-like）红黑粗犷风 UI

**Architecture:** 新建 Godot Theme 资源 `infernal_theme.tres` 作为统一样式源，逐场景重构 .tscn + .gd，先 HUD → HeroPanel → MainMenu → 其余菜单

**Tech Stack:** Godot 4.6, GDScript, StyleBoxFlat, Theme resource

**Spec:** `docs/superpowers/specs/2026-05-16-ui-infernal-redesign.md`

---

## 文件结构

```
新建:
  Art/Theme/infernal_theme.tres          — Godot Theme 资源

修改 (核心):
  Scenes/HUD.tscn                        — 双排技能 + 无头像 + 压缩高度
  Scripts/hud.gd                         — 技能栏双排渲染 + 快捷键标注
  Scenes/HeroPanel.tscn                  — 35/65 分栏 + 高度适配 HUD
  Scripts/hero_panel.gd                  — 遮罩区域调整
  Scenes/MainMenu.tscn                   — 粗犷石版风格
  Scripts/main_menu.gd                   — 应用 Theme
  Scenes/SkillButton.tscn                — 52×52 按钮
  Scripts/Spells/skill_button.gd         — 元素色条 4px

修改 (应用 Theme):
  Scenes/GameModeSelect.tscn + Scripts/game_mode_select.gd
  Scenes/PauseMenu.tscn + Scripts/pause_menu.gd
  Scenes/LevelSelect.tscn + Scripts/level_select.gd
  Scenes/Options.tscn + Scripts/options.gd
  Scenes/HighScores.tscn + Scripts/high_scores.gd
  Scenes/Credits.tscn + Scripts/credits.gd
```

---

### Task 1: 创建 Infernal Theme 资源

**Files:**
- Create: `Art/Theme/infernal_theme.tres`

- [ ] **Step 1: 创建目录并写入 Theme 文件**

```bash
mkdir -p Art/Theme
```

写入 `Art/Theme/infernal_theme.tres`:

```tres
[gd_resource type="Theme" load_steps=4 format=3 uid="uid://infernal_theme_001"]

[resource]

; ===== Button Styles =====
; normal
Button/colors/font_color = Color(0.666, 0.4, 0.267, 1)       ; #aa8866
Button/colors/font_focus_color = Color(1.0, 0.667, 0.267, 1) ; #ffaa44
Button/colors/font_hover_color = Color(1.0, 0.667, 0.267, 1) ; #ffaa44
Button/colors/font_pressed_color = Color(0.533, 0.267, 0.133, 1) ; #884422
Button/colors/icon_normal_color = Color(1, 1, 1, 1)
Button/constants/h_separation = 4
Button/fonts/font = null
Button/font_sizes/font_size = 13
Button/styles/focus = null

; normal state
Button/styles/normal = SubResource("StyleBoxFlat_btn_normal")
; hover state
Button/styles/hover = SubResource("StyleBoxFlat_btn_hover")
; pressed state
Button/styles/pressed = SubResource("StyleBoxFlat_btn_pressed")
; disabled state
Button/styles/disabled = SubResource("StyleBoxFlat_btn_disabled")

; ===== Label Styles =====
Label/colors/font_color = Color(0.666, 0.4, 0.267, 1)        ; #aa8866
Label/font_sizes/font_size = 13

; ===== Panel Styles =====
Panel/styles/panel = SubResource("StyleBoxFlat_panel_bg")
```

- [ ] **Step 2: 验证文件存在**

```bash
ls -la Art/Theme/infernal_theme.tres
```

---

### Task 2: HUD 场景重设计 (.tscn)

**Files:**
- Modify: `Scenes/HUD.tscn`

**关键变更：**
- 底栏高度从 86px → ~60px
- 移除 PortraitBg、HeroPortrait、HPPercentLabel、MPPercentLabel、LevelLabel、TipsLabel
- 技能栏从单排 21 个 → 双排 18 个 (22×22, 间距 3px)
- 快捷槽位从 4 个并排 → 2×2 网格
- EXP 条全宽，居中显示 "LEVEL X"

- [ ] **Step 1: 备份原 HUD.tscn**

```bash
cp Scenes/HUD.tscn Scenes/HUD.tscn.bak
```

- [ ] **Step 2: 重构节点结构**

将 HUD.tscn 的节点树重构为：

```
HUD (CanvasLayer, layer=10)
├── DamageOverlay (ColorRect)              ← 保持不变
├── BottomBar (Panel, 底部定位)
│   ├── BottomBarBg (StyleBoxFlat)         ← 渐变暗红背景
│   ├── LeftInfo (Control, ~120px 宽)
│   │   ├── HPBar (ProgressBar, 6px 高)    ← 暗红填充
│   │   ├── HPLabel ("280")                ← 数值标签
│   │   ├── MPBar (ProgressBar, 6px 高)    ← 蓝色填充
│   │   └── MPLabel ("150")                ← 数值标签
│   ├── SkillSection (Control, flex)
│   │   ├── SkillRow1 (HBoxContainer)      ← 上排 9 个技能
│   │   └── SkillRow2 (HBoxContainer)      ← 下排 9 个技能
│   ├── QuickSlots (GridContainer, 2×2)
│   │   ├── SlotLMB (36×22)
│   │   ├── SlotRMB (36×22)
│   │   ├── SlotShift (36×22)
│   │   └── SlotSpace (36×22)
│   └── ExpBar (ProgressBar, 8px 全宽)
│       └── ExpLabel ("LEVEL X", 居中)
└── BuffContainer (HBoxContainer)          ← 保持不变
    └── RelicContainer (HBoxContainer)     ← 保持不变
```

详细 .tscn 编辑（以文本方式）：

```ini
; BottomBar — 替换为全宽 Panel
[node name="BottomBar" type="Panel" parent="."]
anchor_left = 0.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -62.0
offset_bottom = 0.0
; 使用 StyleBoxFlat 内联样式:
; bg_color = Color(0.157, 0.039, 0.02, 0.92)  渐变底部
; border_width_left = 0, border_width_right = 0
; border_width_top = 2, border_width_bottom = 0
; border_color = Color(0.533, 0.067, 0.0)   #881100

; LeftInfo — 移除头像，只保留 HP/MP 条
[node name="LeftInfo" type="Control" parent="BottomBar"]
anchor_left = 0.0
offset_left = 12.0
offset_right = 140.0
offset_top = 6.0
offset_bottom = 44.0

; HPBar — 6px 高
[node name="HPBar" type="ProgressBar" parent="BottomBar/LeftInfo"]
offset_top = 0.0
offset_bottom = 6.0
offset_right = 100.0
; StyleBoxFlat: bg=#331111, fill=#cc2200

; HPLabel — 右侧数值
[node name="HPLabel" type="Label" parent="BottomBar/LeftInfo"]
offset_left = 104.0
offset_right = 136.0
offset_top = 0.0
offset_bottom = 12.0
text = "280"

; MPBar — 6px 高
[node name="MPBar" type="ProgressBar" parent="BottomBar/LeftInfo"]
offset_top = 10.0
offset_bottom = 16.0
offset_right = 100.0
; StyleBoxFlat: bg=#111133, fill=#2244cc

; MPLabel
[node name="MPLabel" type="Label" parent="BottomBar/LeftInfo"]
offset_left = 104.0
offset_right = 136.0
offset_top = 10.0
offset_bottom = 22.0
text = "150"

; SkillSection — 双排技能容器
[node name="SkillSection" type="Control" parent="BottomBar"]
offset_left = 152.0
offset_right = 872.0
offset_top = 4.0
offset_bottom = 50.0

; SkillRow1 — 上排 9 个
[node name="SkillRow1" type="HBoxContainer" parent="BottomBar/SkillSection"]
offset_top = 0.0
offset_bottom = 22.0
separation = 3

; SkillRow2 — 下排 9 个
[node name="SkillRow2" type="HBoxContainer" parent="BottomBar/SkillSection"]
offset_top = 24.0
offset_bottom = 46.0
separation = 3

; QuickSlots — 2×2 网格
[node name="QuickSlots" type="GridContainer" parent="BottomBar"]
anchor_left = 1.0
anchor_right = 1.0
offset_left = -90.0
offset_right = -12.0
offset_top = 6.0
offset_bottom = 50.0
columns = 2

; ExpBar — 全宽底部
[node name="ExpBar" type="ProgressBar" parent="BottomBar"]
anchor_left = 0.0
anchor_right = 1.0
offset_top = 52.0
offset_bottom = 60.0
; StyleBoxFlat: bg=#110400, fill=linear(#881100 → #cc4400)
```

---

### Task 3: HUD 脚本改造 (hud.gd)

**Files:**
- Modify: `Scripts/hud.gd`

- [ ] **Step 1: 更新 `_ready()` — 移除头像引用，初始化双排技能**

移除以下变量引用：
- `portrait_bg`, `hero_portrait`, `hp_percent_label`, `mp_percent_label`
- `level_label`, `tips_label`

新增变量：
```gdscript
var skill_row1: HBoxContainer
var skill_row2: HBoxContainer
var skill_icons: Array[Control] = []  # 18 个图标节点
```

`_ready()` 中构建双排技能图标：
```gdscript
func _ready():
    # ... 保留现有 signal 连接 ...
    
    skill_row1 = $BottomBar/SkillSection/SkillRow1
    skill_row2 = $BottomBar/SkillSection/SkillRow2
    
    var all_skills = Global.SKILL_IDS  # 21 个技能 ID
    var active_skills = []  # 过滤掉 3 个被动
    var passive_ids = ["fortuna", "telekinesis", "stone_enchanted"]
    for sid in all_skills:
        if sid not in passive_ids:
            active_skills.append(sid)
    
    # 上排 9 个
    for i in range(9):
        var icon = _create_skill_icon(active_skills[i], i)
        skill_row1.add_child(icon)
        skill_icons.append(icon)
    
    # 下排 9 个
    for i in range(9, 18):
        var icon = _create_skill_icon(active_skills[i], i)
        skill_row2.add_child(icon)
        skill_icons.append(icon)
```

- [ ] **Step 2: 实现 `_create_skill_icon()`**

```gdscript
const SKILL_HOTKEYS = [
    "LMB", "RMB", "Z", "X", "C", "2", "3", "4", "Q",
    "R", "E", "U", "F", "G", "H", "B", "N", "O"
]

func _create_skill_icon(skill_id: String, index: int) -> Control:
    var icon = Control.new()
    icon.custom_minimum_size = Vector2(22, 22)
    
    # 背景
    var bg = ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.784, 0.196, 0.0, 0.12)  # rgba(200,50,0,0.12)
    icon.add_child(bg)
    
    # 边框
    var border = ColorRect.new()
    border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    border.color = Color(0, 0, 0, 0)  # 透明填充
    # 用 draw_rect 画边框
    border.draw.connect(func():
        border.draw_rect(Rect2(Vector2.ZERO, border.size), Color(0.4, 0.067, 0.0), false, 1.0)
    )
    icon.add_child(border)
    
    # 技能纹理
    var tex = TextureRect.new()
    tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tex.texture = load("res://Art/Placeholder/%s.png" % skill_id)
    icon.add_child(tex)
    
    # 快捷键标签 (右下角)
    var hotkey_label = Label.new()
    hotkey_label.text = SKILL_HOTKEYS[index]
    hotkey_label.add_theme_font_size_override("font_size", 5)
    hotkey_label.add_theme_color_override("font_color", Color(0.533, 0.4, 0.267))
    hotkey_label.position = Vector2(14, 14)
    icon.add_child(hotkey_label)
    
    # 冷却遮罩 (复用 cooldown_overlay.gd)
    var cd = load("res://Scripts/cooldown_overlay.gd").new()
    cd.name = "CooldownOverlay"
    cd.skill_id = skill_id
    icon.add_child(cd)
    
    # 自动释放指示
    var auto_indicator = ColorRect.new()
    auto_indicator.name = "AutoCastIndicator"
    auto_indicator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    auto_indicator.color = Color(0, 0, 0, 0)  # 默认透明
    auto_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon.add_child(auto_indicator)
    
    # 点击处理
    icon.gui_input.connect(_on_skill_icon_input.bind(skill_id))
    icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    
    return icon
```

- [ ] **Step 3: 更新 `_update_skill_icons()`**

```gdscript
func _update_skill_icons():
    for i in range(skill_icons.size()):
        var skill_id = _get_active_skill_id_at(i)
        var level = Global.skill_levels.get(skill_id, 0)
        var icon = skill_icons[i]
        
        # 未学习 = 灰色半透明
        if level == 0:
            icon.modulate = Color(1, 1, 1, 0.3)
        else:
            icon.modulate = Color(1, 1, 1, 1.0)
```

- [ ] **Step 4: 更新 `_on_skill_icon_input()` — 保留现有点击/右键逻辑**

```gdscript
func _on_skill_icon_input(event: InputEvent, skill_id: String):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _start_quick_slot_assignment(skill_id)
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            _toggle_auto_cast(skill_id)
```

- [ ] **Step 5: 更新 `_update_hp_mp()` — 移除百分比标签和等级标签**

```gdscript
func _update_hp_mp(_val = null):
    $BottomBar/LeftInfo/HPBar.value = Global.health_percent() * 100
    $BottomBar/LeftInfo/HPLabel.text = str(Global.current_health)
    $BottomBar/LeftInfo/MPBar.value = Global.mana_percent() * 100
    $BottomBar/LeftInfo/MPLabel.text = str(Global.current_mana)
```

- [ ] **Step 6: 更新 `_update_exp()` — EXP 条居中文字**

```gdscript
func _update_exp(_val = null):
    $BottomBar/ExpBar.value = Global.experience_percent() * 100
    $BottomBar/ExpBar/ExpLabel.text = "LEVEL " + str(Global.level)
```

- [ ] **Step 7: 移除不再需要的节点引用和更新逻辑**

删除 `_ready()` 中所有对已移除节点的引用（portrait_bg, hero_portrait, hp_percent_label, mp_percent_label, level_label, tips_label）。

---

### Task 4: HeroPanel 场景适配 HUD 共存

**Files:**
- Modify: `Scenes/HeroPanel.tscn`
- Modify: `Scripts/hero_panel.gd`

- [ ] **Step 1: 调整 HeroPanel 高度和遮罩**

在 HeroPanel.tscn 中：
- PanelBg（半透明遮罩 ColorRect）：anchor_bottom 从 1.0 改为 0.937（即 960-60=900px 处），不覆盖 HUD 区域
- Background（Panel）：高度从 570 改为 ≤ 900，anchor_bottom 从 0.5+285 改为 0.937

```ini
; PanelBg — 遮罩仅覆盖 HeroPanel 区域
[node name="PanelBg" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 0.937   ; 900/960, 不覆盖底部 60px HUD
color = Color(0, 0, 0, 0.7)

; Background — 面板主体
[node name="Background" type="Panel" parent="."]
offset_top = 20.0
offset_bottom = 900.0    ; 留底部 60px
```

- [ ] **Step 2: 确保 HUD 在暂停时保持交互**

在 `hero_panel.gd` 中，打开面板时确保 HUD 的 process_mode 正确：

```gdscript
func _open_panel():
    visible = true
    get_tree().paused = true
    
    # 确保 HUD 可交互
    var hud = get_tree().get_first_node_in_group("hud")
    if hud:
        hud.process_mode = Node.PROCESS_MODE_ALWAYS
```

- [ ] **Step 3: 移除开发者按钮的默认显示**

确保 DevRelicButton、DevExp1000、DevExp5000 默认 `visible = false`，仅在 `Global.dev_mode` 时通过代码设置 visible。

---

### Task 5: SkillButton 尺寸升级

**Files:**
- Modify: `Scenes/SkillButton.tscn`
- Modify: `Scripts/Spells/skill_button.gd`

- [ ] **Step 1: 调整 SkillButton.tscn 尺寸**

```ini
[node name="SkillButton" type="Button"]
custom_minimum_size = Vector2(52, 52)

; Border — 边框 ColorRect
[node name="Border" type="ColorRect" parent="."]
color = Color(0.188, 0.157, 0.125, 0.8)  ; Color(0.3,0.25,0.2,0.8) 保持不变

; ElementBar — 元素色条加粗到 4px
[node name="ElementBar" type="ColorRect" parent="."]
offset_bottom = 4.0   ; 从 14x4 → 保持宽，高不变

; Icon
[node name="Icon" type="TextureRect" parent="VBoxContainer"]
custom_minimum_size = Vector2(40, 40)

; LevelLabel
[node name="LevelLabel" type="Label" parent="VBoxContainer"]
theme_override_font_sizes/font_size = 11
```

- [ ] **Step 2: skill_button.gd — 无需逻辑改动，尺寸由 .tscn 控制**

确认 `_get_skill_stats()` 和 tooltip 逻辑保持不变。

---

### Task 6: MainMenu 重设计

**Files:**
- Modify: `Scenes/MainMenu.tscn`
- Modify: `Scripts/main_menu.gd`

- [ ] **Step 1: 重构 MainMenu.tscn 节点**

```ini
; Background — 暗红径向光晕
[node name="Background" type="ColorRect" parent="."]
color = Color(0.039, 0.031, 0.024, 1)  ; #0a0806

; TopLine — 顶部 4px 暗红装饰线
[node name="TopLine" type="ColorRect" parent="."]
offset_bottom = 4.0
color = Color(0.4, 0.067, 0.0)  ; #661100

; BottomLine — 底部 4px 暗红装饰线
[node name="BottomLine" type="ColorRect" parent="."]
anchor_top = 1.0
anchor_bottom = 1.0
offset_top = -4.0
color = Color(0.4, 0.067, 0.0)  ; #661100

; TitleLabel — 粗体无衬线 + 重阴影
[node name="TitleLabel" type="Label" parent="CenterContainer/VBoxContainer"]
text = "EVIL INVASION"
theme_override_font_sizes/font_size = 38
theme_override_colors/font_color = Color(0.867, 0.133, 0.0)  ; #dd2200
; 阴影通过 theme_override_constants/shadow_offset_x = 4 等设置

; SubtitleLabel — 移除或缩小
[node name="SubtitleLabel" type="Label" parent="CenterContainer/VBoxContainer"]
theme_override_font_sizes/font_size = 12
theme_override_colors/font_color = Color(0.533, 0.267, 0.133)  ; #884422
```

- [ ] **Step 2: 按钮样式**

每个按钮通过 Theme 覆盖：
```ini
; NewGameButton — 高亮按钮
theme_override_styles/normal = StyleBoxFlat(bg=#881100, border=2px #cc2200)
theme_override_styles/hover = StyleBoxFlat(bg=#aa2200, border=2px #dd4400)
theme_override_colors/font_color = Color(1.0, 0.8, 0.533)  ; #ffcc88
custom_minimum_size = Vector2(240, 44)

; 其他按钮
theme_override_styles/normal = StyleBoxFlat(bg=#661100, border=2px #441100)
theme_override_styles/hover = StyleBoxFlat(bg=#992200, border=2px #cc2200)
theme_override_colors/font_color = Color(0.6, 0.467, 0.4)  ; #997766
custom_minimum_size = Vector2(240, 40)
```

- [ ] **Step 3: main_menu.gd 微调**

```gdscript
func _ready():
    # 应用 Theme
    var theme = load("res://Art/Theme/infernal_theme.tres")
    if theme:
        # 全局应用，按钮和 Label 自动获得样式
        pass
    
    # 背景光晕效果 — 用 ShaderMaterial 或渐变 ColorRect 叠加
    _setup_background_glow()
    
    # 保留现有存档检测逻辑
    _check_save_file()

func _setup_background_glow():
    var glow = ColorRect.new()
    glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    # 径向渐变: 中央上方暗红光晕
    var shader = ShaderMaterial.new()
    # 简单实现: 用半透明 ColorRect + 渐变纹理
    glow.material = shader
    add_child(glow)
    move_child(glow, 0)  # 放到最底层
```

---

### Task 7: 其余菜单应用 Theme

**Files:**
- Modify: `Scenes/GameModeSelect.tscn`, `Scenes/PauseMenu.tscn`, `Scenes/LevelSelect.tscn`, `Scenes/Options.tscn`, `Scenes/HighScores.tscn`, `Scenes/Credits.tscn`

- [ ] **Step 1: 每个场景统一做以下调整**

1. 背景色改为 `Color(0.039, 0.031, 0.024)` (#0a0806)
2. 标题色改为 `Color(0.867, 0.133, 0.0)` (#dd2200)，font_size 40
3. 按钮应用 Infernal StyleBoxFlat（同 MainMenu 次要按钮样式）
4. 分隔线色改为 `Color(0.4, 0.067, 0.0)` (#661100)

- [ ] **Step 2: PauseMenu 特殊处理**

PauseMenu 已有自定义 StyleBoxFlat（正常），将配色更新为 Infernal 红黑：
- 面板背景: `Color(0.059, 0.031, 0.02, 0.95)` 替代原 `Color(0.15, 0.1, 0.05, 0.95)`
- 按钮 normal: `#661100` 替代原 `#3f2e14`
- 按钮 hover: `#992200` 替代原 `#59401a`
- ResumeButton 保持高亮样式

- [ ] **Step 3: Options 补充控件样式**

- CheckBox: 应用 Theme 中的 checkbox 样式
- HSlider: 应用 Theme 中的 slider 样式
- 当前只有 3 个设置项，保持不变

---

### Task 8: 集成验证

- [ ] **Step 1: 启动游戏，验证 MainMenu**

```bash
# 在 Godot 编辑器中运行项目 (F5)
# 验证:
# - 标题 EVIL INVASION 粗体 #dd2200 + 重阴影
# - 按钮 2px 粗边框，hover 变亮
# - 顶部/底部暗红装饰线可见
```

- [ ] **Step 2: 进入游戏，验证 HUD**

```
验证:
- 底栏高度约 60px（明显比原来矮）
- 左侧 HP/MP 条 6px 高，右侧数值标签
- 中间 18 个技能图标两排 9+9，间距 3px
- 每个图标右下角有快捷键标注
- 右侧 2×2 快捷槽位 LMB/RMB/Shift/Space
- 底部 EXP 条全宽，居中 "LEVEL X"
- 无头像、无 TipsLabel
```

- [ ] **Step 3: 按 T 打开 HeroPanel，验证 HUD 共存**

```
验证:
- HeroPanel 底部不覆盖 HUD 区域
- HUD 保持可见，技能图标可点击
- 半透明遮罩仅覆盖 HeroPanel 区域（HUD 上方）
- 游戏暂停，HUD 仍可交互
```

- [ ] **Step 4: 验证 HeroPanel 布局**

```
验证:
- 左右分栏约 35/65
- 属性行 32px 高，隔行变色
- 技能按钮 52×52，元素色条 4px
- 属性 [+] 按钮正常
- 开发者按钮默认隐藏
```

- [ ] **Step 5: 验证其余菜单**

```
验证:
- GameModeSelect: 下拉框 + 按钮样式正确
- PauseMenu: 面板 + 按钮红黑风格
- LevelSelect: 关卡按钮样式正确
- Options: CheckBox/HSlider 样式正确
- HighScores: 表头/行颜色正确
- Credits: 文字 + 按钮正确
```