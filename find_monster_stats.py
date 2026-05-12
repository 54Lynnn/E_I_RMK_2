import struct

dll_path = r'e:\EvilInvasion\Logic.dll'
with open(dll_path, 'rb') as f:
    data = f.read()

# 搜索 MonsterBalance.txt 附近的代码
pos = data.find(b'MonsterBalance.txt')
print('MonsterBalance.txt found at: 0x' + hex(pos)[2:])

# 提取周围的字符串
start = max(0, pos - 200)
end = min(len(data), pos + 500)

strings = []
i = start
while i < end:
    if 32 <= data[i] <= 126:
        str_start = i
        while i < end and 32 <= data[i] <= 126:
            i += 1
        s = data[str_start:i].decode('ascii', errors='replace')
        if len(s) >= 3:
            strings.append((str_start, s))
    i += 1

print('\n=== Strings around MonsterBalance.txt ===')
for addr, s in strings:
    print('  0x' + hex(addr)[2:] + ': "' + s + '"')

# 搜索可能的怪物属性名
print('\n=== Searching for monster stat patterns ===')
stat_patterns = [b'HEALTH', b'DAMAGE', b'SPEED', b'EXPERIENCE', b'EXP', b'ATTACK', b'DEFENSE']
for pattern in stat_patterns:
    pos = 0
    while True:
        pos = data.find(pattern, pos)
        if pos < 0:
            break
        # 提取上下文
        ctx_start = max(0, pos - 30)
        ctx_end = min(len(data), pos + 50)
        ctx = data[ctx_start:ctx_end]
        # 只保留可打印字符
        clean = b''
        for b in ctx:
            if 32 <= b <= 126:
                clean += bytes([b])
            else:
                clean += b'|'
        print('  Found ' + pattern.decode() + ' at 0x' + hex(pos)[2:] + ': ' + clean.decode('ascii', errors='replace'))
        pos += 1
        break  # 只显示第一个匹配
