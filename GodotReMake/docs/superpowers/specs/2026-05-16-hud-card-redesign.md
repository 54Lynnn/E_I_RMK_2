# Bottom HUD 精致暗黑卡片化 Redesign

**Date:** 2026-05-16
**Status:** Approved — Ready for Implementation

---

## Design Decisions

| 项目 | 选择 |
|------|------|
| 整体风格 | 精致暗黑卡片化（Diablo 4 风格） |
| HP/MP | 横条 + 数值 + 百分比 |
| EXP | 熔岩能量槽（渐变 + 居中 LEVEL X） |
| 卡片边框 | 2px #661100 粗框 + 红色外发光 |
| 底栏高度 | 68px（保持不变） |

---

## Layout Structure

```
BottomBar (68px, bg=#070302, top_border=2px #881100)
├── HPMPCard (Panel, 158px, bg=#0f0704, border=2px #661100, glow)
│   ├── HP row: "HP" label + ProgressBar(85%) + "280" + "(100%)"
│   └── MP row: "MP" label + ProgressBar(70%) + "150" + "(70%)"
├── SkillsCard (Panel, flex, bg=#0f0704, border=2px #661100, glow)
│   └── SkillRow1 (HBoxContainer, 18 buttons)
│       └── SkillBtn_xxx (30×30, bg=#150805, border=1px #441100)
│           ├── Icon (28×28)
│           └── HotkeyLabel (右下角, #ffcc44, font_size=7)
├── QuickSlotsCard (Panel, 86px, bg=#0f0704, border=2px #661100, glow)
│   └── GridContainer (2×2)
│       └── SlotX (Panel, bg=#150805, border=1px #552200)
│           ├── SlotXIcon (16×16)
│           └── SlotXLabel (right, #ffaa44)
└── ExpBar (8px, full_width, lava_gradient, LEVEL X centered above)
```

---

## Color Palette

| 用途 | Hex | 说明 |
|------|-----|------|
| 底部栏背景 | #070302 | 极暗底 |
| 卡片背景 | #0f0704 | 暗红棕 |
| 卡片边框 | #661100 | 粗框 2px |
| 卡片发光 | rgba(102,17,0,0.2) | box-shadow glow |
| 顶部分隔线 | #881100 | 2px solid |
| HP 条填充 | #cc2200 | 红橙渐变 |
| MP 条填充 | #2244cc | 蓝渐变 |
| 技能凹槽背景 | #150805 | 更深暗棕 |
| 技能凹槽边框 | #441100 | 1px |
| 快捷槽背景 | #150805 | 同凹槽 |
| 快捷槽边框 | #552200 | 1px 稍亮 |
| 快捷键文字 | #ffcc44 | 金黄 |
| 快捷槽文字 | #ffaa44 | 橙黄 |
| EXP 熔岩高亮 | #ff4400 | 亮橙 |

---

## Skill Button States

| 状态 | 表现 |
|------|------|
| 已解锁 (level ≥ 1) | 彩色 modulate(1,1,1,1), #441100 边框 |
| 未解锁 (level = 0) | 灰色 modulate(0.5,0.5,0.5,0.7), #1a0a05 边框, opacity 0.5 |
| 自动释放 | 加粗 #cc4400 边框 + 橙色 glow + 旋转虚线环 |
| 冷却中 | 黑色半透明遮罩 + 倒计时文字 |

---

## HP/MP Card Detail

- Width: 158px, anchored left
- Background: #0f0704, border: 2px #661100, box-shadow glow
- "HP" / "MP" labels: font_size=9, bold, with matching colored text-shadow glow
- ProgressBar: height=10px, dark background (#1a0400 / #04041a), 3px border-radius
- Fill: horizontal gradient with inset highlight
- Value label: font_size=9, bold
- Percent label: font_size=7, muted

## Skills Card Detail

- Flex-fill between HPMPCard and QuickSlotsCard
- Background: #0f0704, border: 2px #661100, box-shadow glow
- 18 skill buttons at 30×30, separation=3px
- Each button: bg=#150805, border=1px #441100, inner shadow
- Icon: 28×28, centered in button
- HotkeyLabel: 9px tall bottom strip, right-aligned, #ffcc44, font_size=7

## QuickSlots Card Detail

- Width: 86px, anchored right
- Background: #0f0704, border: 2px #661100, box-shadow glow
- 2×2 GridContainer with h_separation=2, v_separation=2
- Each slot: Panel, bg=#150805, border=1px #552200
- Slot icon: 16×16 left
- Slot label: right-aligned, #ffaa44, font_size=7

## ExpBar Detail

- 8px tall, full width at bottom of BottomBar
- Dark background #0d0200, border: 1px #551100
- Fill: lava gradient #220000 → #cc2200 → #ff4400 → #cc2200 → #220000
- "LEVEL X" text: centered above bar, #ffcc88, font_size=9, bold, letter-spacing=1px
- Text shadow for readability over game content

---

## Files to Modify

| File | Changes |
|------|---------|
| `Scenes/HUD.tscn` | Rewrite BottomBar structure: add HPMPCard/SkillsCard/QuickSlotsCard Panels, update all StyleBoxes, reposition children |
| `Scripts/hud.gd` | Update @onready paths, may need minor adjustments |

## Migration Notes

- HP/MP bars: keep current ProgressBar + Label + PercentLabel nodes, just re-parent into HPMPCard
- Skill buttons: keep current static SkillRow1 + 18 SkillBtn_xxx nodes, re-parent into SkillsCard
- QuickSlots: keep current GridContainer + 4 SlotX Panels, re-parent into QuickSlotsCard
- ExpBar + ExpLabel: keep current, update StyleBox for lava gradient
- BottomBar: update theme_override_styles/panel for new background
- All existing signal connections and runtime logic in hud.gd remain unchanged