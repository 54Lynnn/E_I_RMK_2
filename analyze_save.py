import struct
import os

print('深入分析存档文件')
print('=' * 60)

save_file = 'E:\\EvilInvasion\\Profiles\\123.ei'

if not os.path.exists(save_file):
    print('存档文件不存在')
    exit(1)

with open(save_file, 'rb') as f:
    data = f.read()

print(f'存档大小: {len(data)} bytes')
print(f'文件路径: {save_file}')
print()

# 详细解析存档
print('存档内容详细解析:')
print('-' * 60)

# 前8字节可能是文件头
print('\n文件头:')
print(f'  字节 0-3: {data[:4].hex()}')
print(f'  字节 4-7: {data[4:8].hex()}')

# 解析各种数据类型
print('\n解析为4字节整数（小端序）:')
for i in range(0, len(data)-3, 4):
    val = struct.unpack('<I', data[i:i+4])[0]
    print(f'  偏移 {i:3d}: {val:10d} (0x{val:08X})')

print('\n解析为4字节浮点数:')
for i in range(0, len(data)-3, 4):
    val = struct.unpack('<f', data[i:i+4])[0]
    if abs(val) > 0.01 and abs(val) < 1000000:
        print(f'  偏移 {i:3d}: {val:12.2f}')

print('\n解析为2字节整数:')
for i in range(0, len(data)-1, 2):
    val = struct.unpack('<H', data[i:i+2])[0]
    if val > 0 and val < 10000:
        print(f'  偏移 {i:3d}: {val:6d}')

print('\n解析为1字节整数:')
for i in range(len(data)):
    val = data[i]
    if val > 0 and val < 100:
        print(f'  偏移 {i:3d}: {val:3d}')

print('\n' + '=' * 60)
print('存档数据结构推测:')
print('-' * 60)

# 基于已知信息的推测
print('偏移  0-7: 文件头/魔数')
print('偏移  8-11: 可能是金币/分数 (34)')
print('偏移 12-15: 未知')
print('偏移 16-19: 可能是等级 (1)')
print('偏移 20-23: 可能是经验值 (112430)')
print('偏移 24-27: 可能是力量 (41)')
print('偏移 28-31: 可能是敏捷 (51)')
print('偏移 32-35: 可能是智力 (41)')
print('偏移 36-39: 可能是体质 (61)')
print('偏移 40-43: 可能是精神 (61)')
print('偏移 44-47: 可能是技能点 (10)')
print('偏移 48-51: 可能是属性点 (1)')

print('\n如果偏移20-23是经验值 112430:')
print('这可能是一个高级存档！')
print('等级1却有112430经验值？这不太可能...')
print('或者这是某种编码后的值')

# 尝试不同的解释
print('\n尝试解码偏移20-23的值:')
val = struct.unpack('<I', data[20:24])[0]
print(f'  作为无符号整数: {val}')
print(f'  作为有符号整数: {struct.unpack("<i", data[20:24])[0]}')
print(f'  作为浮点数: {struct.unpack("<f", data[20:24])[0]}')

# 检查是否是某种编码
print(f'  除以100: {val / 100}')
print(f'  除以1000: {val / 1000}')
print(f'  除以150: {val / 150}')

print('\n' + '=' * 60)
print('结论:')
print('存档文件包含英雄数据，但经验值的具体位置和格式需要进一步验证')
print('建议: 在游戏中升级后保存，然后对比存档文件的变化')
