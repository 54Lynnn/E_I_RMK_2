import os
import struct
import re

# 读取 Logic.dll 文件
with open('E:\\EvilInvasion\\Logic.dll', 'rb') as f:
    data = f.read()

print(f'Logic.dll 文件大小: {len(data)} bytes')

# 搜索经验值相关的字符串
keywords = [b'experience', b'EXPERIENCE', b'Experience', b'level', b'LEVEL', b'Level',
            b'exp', b'EXP', b'next', b'NEXT', b'required', b'REQUIRED',
            b'hero_level', b'HERO_LEVEL', b'player_level', b'PLAYER_LEVEL']

print('\n搜索关键词...')
found_keywords = []
for keyword in keywords:
    if keyword in data:
        found_keywords.append(keyword)
        print(f'  找到: {keyword.decode()}')

# 搜索可能的数字模式（经验值公式通常包含数字）
print('\n搜索可能的数字常量...')
# 搜索 100 的倍数（常见经验值基数）
for i in range(50, 5000, 50):
    pattern = struct.pack('<I', i)
    if pattern in data:
        print(f'  找到数字: {i}')
        if i > 500:
            break

# 搜索浮点数模式（可能是经验值公式系数）
print('\n搜索可能的浮点数系数...')
for i in range(1, 100):
    f_val = i * 0.1
    pattern = struct.pack('<f', f_val)
    if pattern in data:
        print(f'  找到浮点数: {f_val}')
    if i > 20:
        break

# 搜索特定的经验值模式（如 100, 200, 300... 或 100, 250, 500...）
print('\n搜索经验值序列模式...')
# 常见经验值序列
exp_sequences = [
    [100, 200, 300, 400, 500],
    [100, 250, 500, 1000, 2000],
    [100, 300, 600, 1000, 1500],
    [50, 150, 300, 500, 750],
    [100, 200, 400, 800, 1600],
]

for seq in exp_sequences:
    found = True
    for val in seq:
        pattern = struct.pack('<I', val)
        if pattern not in data:
            found = False
            break
    if found:
        print(f'  找到序列: {seq}')

print('\n完成！')
