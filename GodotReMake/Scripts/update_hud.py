#!/usr/bin/env python3
"""
批量更新 HUD.tscn 文件：
1. 技能按钮 30x30 -> 36x36
2. Icon 尺寸同步调整
3. HP/MP 条高度 18px -> 10px
4. 百分比标签位置调整
5. 左侧宽度 170px -> 120px
"""

import re

with open("Scenes/HUD.tscn", "r", encoding="utf-8") as f:
    content = f.read()

# 1. 技能按钮 custom_minimum_size 30x30 -> 36x36
content = content.replace("custom_minimum_size = Vector2(30, 30)", "custom_minimum_size = Vector2(36, 36)")

# 2. Icon 尺寸调整 (offset_right/offset_bottom 从 ~31-33 改为 ~35-37)
# 匹配 Icon 节点的 offset 行
# 原: offset_left = 3.0, offset_top = 1.0, offset_right = 33.0, offset_bottom = 31.0
# 新: offset_left = 1.0, offset_top = 1.0, offset_right = 35.0, offset_bottom = 35.0
content = content.replace("offset_left = 3.0\noffset_top = 1.0\noffset_right = 33.0\noffset_bottom = 31.0",
                          "offset_left = 1.0\noffset_top = 1.0\noffset_right = 35.0\noffset_bottom = 35.0")
content = content.replace("offset_left = 1.0\noffset_top = 1.0\noffset_right = 31.0\noffset_bottom = 31.0",
                          "offset_left = 1.0\noffset_top = 1.0\noffset_right = 35.0\noffset_bottom = 35.0")

# 3. HP/MP 条高度调整: offset_bottom - offset_top = 10px
# HPBar: offset_top=4, offset_bottom=22 -> offset_top=2, offset_bottom=12
content = content.replace(
    """[node name="HPBar" type="ProgressBar" parent="BottomBar/LeftInfo" unique_id=882335034]
layout_mode = 0
offset_left = 12.0
offset_top = 4.0
offset_right = 108.0
offset_bottom = 22.0""",
    """[node name="HPBar" type="ProgressBar" parent="BottomBar/LeftInfo" unique_id=882335034]
layout_mode = 0
offset_left = 8.0
offset_top = 2.0
offset_right = 84.0
offset_bottom = 12.0"""
)

# MPBar: offset_top=30, offset_bottom=48 -> offset_top=20, offset_bottom=30
content = content.replace(
    """[node name="MPBar" type="ProgressBar" parent="BottomBar/LeftInfo" unique_id=1997986946]
layout_mode = 0
offset_left = 12.0
offset_top = 30.0
offset_right = 108.0
offset_bottom = 48.0""",
    """[node name="MPBar" type="ProgressBar" parent="BottomBar/LeftInfo" unique_id=1997986946]
layout_mode = 0
offset_left = 8.0
offset_top = 20.0
offset_right = 84.0
offset_bottom = 30.0"""
)

# 4. HPLabel 位置调整 (放在 HPBar 右侧)
content = content.replace(
    """[node name="HPLabel" type="Label" parent="BottomBar/LeftInfo" unique_id=2115120684]
layout_mode = 0
offset_left = 112.0
offset_top = 4.0
offset_right = 140.0
offset_bottom = 22.0""",
    """[node name="HPLabel" type="Label" parent="BottomBar/LeftInfo" unique_id=2115120684]
layout_mode = 0
offset_left = 88.0
offset_top = 0.0
offset_right = 116.0
offset_bottom = 14.0"""
)

# 5. MPLabel 位置调整 (放在 MPBar 右侧)
content = content.replace(
    """[node name="MPLabel" type="Label" parent="BottomBar/LeftInfo" unique_id=1874287130]
layout_mode = 0
offset_left = 112.0
offset_top = 30.0
offset_right = 140.0
offset_bottom = 48.0""",
    """[node name="MPLabel" type="Label" parent="BottomBar/LeftInfo" unique_id=1874287130]
layout_mode = 0
offset_left = 88.0
offset_top = 18.0
offset_right = 116.0
offset_bottom = 32.0"""
)

# 6. HPPercentLabel 移到 HP/MP 之间
content = content.replace(
    """[node name="HPPercentLabel" type="Label" parent="BottomBar/LeftInfo" unique_id=470042140]
layout_mode = 0
offset_left = 142.0
offset_top = 4.0
offset_right = 170.0
offset_bottom = 22.0""",
    """[node name="HPPercentLabel" type="Label" parent="BottomBar/LeftInfo" unique_id=470042140]
layout_mode = 0
offset_left = 8.0
offset_top = 12.0
offset_right = 116.0
offset_bottom = 20.0"""
)

# 7. MPPercentLabel 也移到中间（或者可以删除，但先保留调整位置）
content = content.replace(
    """[node name="MPPercentLabel" type="Label" parent="BottomBar/LeftInfo" unique_id=1742631555]
layout_mode = 0
offset_left = 142.0
offset_top = 30.0
offset_right = 170.0
offset_bottom = 48.0""",
    """[node name="MPPercentLabel" type="Label" parent="BottomBar/LeftInfo" unique_id=1742631555]
layout_mode = 0
offset_left = 8.0
offset_top = 30.0
offset_right = 116.0
offset_bottom = 38.0"""
)

# 8. LeftInfo 宽度 170 -> 120
content = content.replace(
    """[node name="LeftInfo" type="Control" parent="BottomBar" unique_id=12585000]
layout_mode = 1
anchors_preset = 9
anchor_bottom = 1.0
offset_right = 170.0
offset_bottom = -12.0""",
    """[node name="LeftInfo" type="Control" parent="BottomBar" unique_id=12585000]
layout_mode = 1
anchors_preset = 9
anchor_bottom = 1.0
offset_right = 120.0
offset_bottom = -12.0"""
)

# 9. SkillSection 左侧偏移 178 -> 128 (配合 LeftInfo 120px + 8px 间距)
content = content.replace(
    """[node name="SkillSection" type="Control" parent="BottomBar" unique_id=1193662387]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 178.0
offset_top = 4.0
offset_right = -90.0
offset_bottom = -12.0""",
    """[node name="SkillSection" type="Control" parent="BottomBar" unique_id=1193662387]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 128.0
offset_top = 4.0
offset_right = -90.0
offset_bottom = -12.0"""
)

# 10. SkillRow1 高度调整 51 -> 42 (适应 36x36 按钮)
content = content.replace(
    """[node name="SkillRow1" type="HBoxContainer" parent="BottomBar/SkillSection" unique_id=1642081411]
layout_mode = 0
offset_right = 500.0
offset_bottom = 51.0""",
    """[node name="SkillRow1" type="HBoxContainer" parent="BottomBar/SkillSection" unique_id=1642081411]
layout_mode = 0
offset_right = 500.0
offset_bottom = 42.0"""
)

with open("Scenes/HUD.tscn", "w", encoding="utf-8") as f:
    f.write(content)

print("HUD.tscn 更新完成！")
print("主要改动:")
print("- 技能按钮: 30x30 -> 36x36")
print("- Icon 尺寸: 28x28 -> 34x34")
print("- HP/MP 条高度: 18px -> 10px")
print("- 左侧宽度: 170px -> 120px")
print("- SkillSection 左偏移: 178 -> 128")
