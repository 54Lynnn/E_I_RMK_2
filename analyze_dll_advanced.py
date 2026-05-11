import struct

# 读取 Logic.dll 文件
with open('E:\\EvilInvasion\\Logic.dll', 'rb') as f:
    data = f.read()

print(f'Logic.dll 文件大小: {len(data)} bytes')

# 搜索 "EXPERIENCE" 字符串出现的位置
exp_positions = []
pos = 0
while True:
    pos = data.find(b'EXPERIENCE', pos)
    if pos == -1:
        break
    exp_positions.append(pos)
    pos += 1

print(f'\n找到 {len(exp_positions)} 个 "EXPERIENCE" 出现位置')

# 在每个位置周围搜索数字模式
for i, pos in enumerate(exp_positions[:5]):  # 只查看前5个
    print(f'\n位置 {i}: 0x{pos:08X}')
    
    # 显示前后200字节
    start = max(0, pos - 200)
    end = min(len(data), pos + 200)
    chunk = data[start:end]
    
    # 尝试解码为文本
    try:
        text = chunk.decode('ascii', errors='replace')
        print(f'  文本内容: {text[:200]}')
    except:
        print(f'  二进制内容')
    
    # 搜索附近的整数
    print(f'  附近整数:')
    for offset in range(-100, 100, 4):
        if pos + offset >= 0 and pos + offset + 4 <= len(data):
            val = struct.unpack('<I', data[pos+offset:pos+offset+4])[0]
            if 10 < val < 100000:  # 合理的经验值范围
                print(f'    偏移 {offset}: {val}')

# 搜索 "Level" 或 "LEVEL" 附近的内容
print(f'\n\n搜索 "Level" 相关内容...')
level_positions = []
pos = 0
while True:
    pos = data.find(b'Level', pos)
    if pos == -1:
        break
    level_positions.append(pos)
    pos += 1

print(f'找到 {len(level_positions)} 个 "Level" 出现位置')

# 查看前几个位置
for i, pos in enumerate(level_positions[:3]):
    print(f'\n位置 {i}: 0x{pos:08X}')
    start = max(0, pos - 100)
    end = min(len(data), pos + 100)
    chunk = data[start:end]
    try:
        text = chunk.decode('ascii', errors='replace')
        print(f'  内容: {text}')
    except:
        print(f'  二进制内容')

# 搜索乘法或加法相关的浮点数（可能是公式系数）
print(f'\n\n搜索可能的公式系数...')
coefficients = [1.0, 1.5, 2.0, 2.5, 3.0, 5.0, 10.0, 100.0]
for coeff in coefficients:
    pattern = struct.pack('<f', coeff)
    if pattern in data:
        print(f'  找到系数: {coeff}')

print('\n完成！')
